sprite = """
F999F
26227
F1F8F
F1F1F
99F11
F8F1F
F8F9F
F1244
F9F9F
F9F1F
F9F99
E9E9E
F888F
E999E
F8F8F
F8F88
"""

cleaned = list(filter(lambda s: len(s) == 5, sprite.splitlines()))
i = 0
for sprite in cleaned:
    for byte in sprite:
        print(f"self.memory[{i}] = 0x{byte}0;")
        i+=1
