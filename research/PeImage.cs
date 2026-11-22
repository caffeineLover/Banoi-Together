// Read-only PE inspection helper for the quest/chat investigation.
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public sealed class PeImage {
    public readonly byte[] Bytes;
    public readonly ulong Base;
    public readonly uint Timestamp;
    public readonly List<Section> Sections = new List<Section>();
    public readonly List<Function> Functions = new List<Function>();
    public readonly Dictionary<uint,string> Imports = new Dictionary<uint,string>();
    public sealed class Section { public string Name; public uint Rva, Size, Raw, RawSize; }
    public sealed class Function { public uint Start, End; public override string ToString() { return String.Format("RVA {0:X8}-{1:X8}", Start, End); } }
    public sealed class Reference { public uint Instruction, Target; public Function Function; public override string ToString() { return String.Format("xref RVA {0:X8} -> {1:X8}, {2}", Instruction, Target, Function); } }
    public PeImage(string path) {
        Bytes = File.ReadAllBytes(path);
        int pe = (int)U32(0x3c), optional = pe + 24;
        if (U32(pe) != 0x4550 || U16(optional) != 0x20b) throw new Exception("Expected PE32+");
        Timestamp = U32(pe + 8);
        Base = U64(optional + 24);
        int table = optional + U16(pe + 20);
        for (int i = 0; i < U16(pe + 6); i++) {
            int p = table + 40 * i;
            Sections.Add(new Section { Name = Encoding.ASCII.GetString(Bytes,p,8).TrimEnd('\0'), Size=U32(p+8), Rva=U32(p+12), RawSize=U32(p+16), Raw=U32(p+20) });
        }
        uint pdata = U32(optional + 112 + 8 * 3), length = U32(optional + 116 + 8 * 3);
        if (pdata != 0) { int p = Offset(pdata); for(uint i=0;i+12<=length;i+=12) Functions.Add(new Function { Start=U32(p+(int)i), End=U32(p+(int)i+4) }); }
        uint importRva=U32(optional+120);
        if(importRva!=0) { for(int p=Offset(importRva);U32(p+12)!=0;p+=20) {
            string dll=Ascii(U32(p+12)); uint lookup=U32(p),iat=U32(p+16); if(lookup==0) lookup=iat;
            int tableOffset=Offset(lookup); for(uint j=0;U64(tableOffset+(int)j*8)!=0;j++) { ulong entry=U64(tableOffset+(int)j*8); if((entry>>63)==0) Imports[iat+j*8]=dll+"!"+Ascii((uint)entry+2); }
        } }
    }
    public ushort U16(int p) { return BitConverter.ToUInt16(Bytes,p); }
    public uint U32(int p) { return BitConverter.ToUInt32(Bytes,p); }
    public ulong U64(int p) { return BitConverter.ToUInt64(Bytes,p); }
    public string Ascii(uint rva) { int start=Offset(rva),end=start; while(end<Bytes.Length && Bytes[end]!=0 && end-start<500) end++; return Encoding.ASCII.GetString(Bytes,start,end-start); }
    public int Offset(uint rva) { foreach(var s in Sections) if(rva>=s.Rva && rva<s.Rva+s.RawSize) return (int)(rva-s.Rva+s.Raw); throw new Exception("RVA outside file: "+rva.ToString("X")); }
    public uint Rva(int offset) { foreach(var s in Sections) if(offset>=s.Raw && offset<s.Raw+s.RawSize) return (uint)(offset-s.Raw+s.Rva); throw new Exception("File offset outside sections"); }
    public Function Containing(uint rva) { int lo=0,hi=Functions.Count-1; while(lo<=hi) { int mid=(lo+hi)/2; var f=Functions[mid]; if(rva<f.Start) hi=mid-1; else if(rva>=f.End) lo=mid+1; else return f; } return null; }
    public List<uint> FindString(string value) {
        byte[] needle=Encoding.ASCII.GetBytes(value+"\0"); var hits=new List<uint>();
        for(int i=0;i+needle.Length<=Bytes.Length;i++) { if(Bytes[i]!=needle[0]) continue; int j=1; for(;j<needle.Length && Bytes[i+j]==needle[j];j++) {} if(j==needle.Length) { try { hits.Add(Rva(i)); } catch {} } }
        return hits;
    }
    public List<Reference> RipReferences(uint target) {
        var hits=new List<Reference>();
        foreach(var s in Sections) { if(s.Name!=".text") continue;
            for(int i=(int)s.Raw;i+7<=s.Raw+s.RawSize;i++) {
                if(Bytes[i]==0xFF && (Bytes[i+1]==0x15 || Bytes[i+1]==0x25)) {
                    uint callRva=(uint)(i-s.Raw+s.Rva);
                    if((long)callRva+6+BitConverter.ToInt32(Bytes,i+2)==target) hits.Add(new Reference {Instruction=callRva,Target=target,Function=Containing(callRva)});
                }
                if((Bytes[i]&0xF0)!=0x40 || (Bytes[i+1]!=0x8D && Bytes[i+1]!=0x8B) || (Bytes[i+2]&0xC7)!=5) continue;
                uint insn=(uint)(i-s.Raw+s.Rva); long dest=(long)insn+7+BitConverter.ToInt32(Bytes,i+3);
                if(dest==target) hits.Add(new Reference {Instruction=insn,Target=target,Function=Containing(insn)});
            }
        }
        return hits;
    }
    public List<Reference> CallsTo(uint target) {
        var hits=new List<Reference>();
        foreach(var s in Sections) { if(s.Name!=".text") continue;
            for(int i=(int)s.Raw;i+5<=s.Raw+s.RawSize;i++) { if(Bytes[i]!=0xE8 && Bytes[i]!=0xE9) continue; uint insn=(uint)(i-s.Raw+s.Rva); if((long)insn+5+BitConverter.ToInt32(Bytes,i+1)==target) hits.Add(new Reference {Instruction=insn,Target=target,Function=Containing(insn)}); }
        }
        return hits;
    }
    public List<uint> PointersTo(ulong target) { var result=new List<uint>(); for(int i=0;i+8<=Bytes.Length;i+=8) if(U64(i)==target) { try {result.Add(Rva(i));}catch {} } return result; }
    public List<uint> VTables(string className) {
        var result=new List<uint>(); foreach(uint typeName in FindString(".?AV"+className+"@@")) {
            uint descriptor=typeName-16;
            foreach(var s in Sections) { if(s.Name!=".rdata") continue;
                for(int p=(int)s.Raw+12;p+12<s.Raw+s.RawSize;p+=4) { if(U32(p)!=descriptor || U32(p-12)!=1 || U32(p+8)!=Rva(p-12)) continue;
                    foreach(uint colPointer in PointersTo(Base+Rva(p-12))) result.Add(colPointer+8);
                }
            }
        } return result;
    }
}
