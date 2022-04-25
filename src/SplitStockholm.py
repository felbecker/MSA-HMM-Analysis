import sys

file = sys.argv[1]
print(file)
with open(file, "r", encoding = "ISO-8859-1") as file:
    out_stockholm = ""
    out_name = ""
    for line in file:
        if line.strip() == "# STOCKHOLM 1.0":
            if not out_stockholm == "":
                with open(sys.argv[2]+"/"+out_name+".stockholm", "w") as out_file:
                    out_file.write(out_stockholm)
            out_stockholm = ""
        if line[:7] == "#=GF AC":
            out_name = line[10:].strip()
        out_stockholm += line
