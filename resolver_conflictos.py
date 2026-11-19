import re, sys

ruta = sys.argv[1]
texto = open(ruta, encoding='utf-8', newline='').read()

patron = re.compile(
    r'<<<<<<< [^\r\n]*\r?\n.*?=======\r?\n(.*?)>>>>>>> [^\r\n]*\r?\n',
    re.S,
)
nuevo, n = patron.subn(lambda m: m.group(1), texto)

open(ruta, 'w', encoding='utf-8', newline='').write(nuevo)
print(f'{n} conflictos resueltos en {ruta}')
