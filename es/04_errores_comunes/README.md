# 04 — Errores reales encontrados en este clúster (y cómo se diagnosticaron)

Los tutoriales genéricos de PBS suelen detenerse en "así es como envías un trabajo."
Estos son problemas reales, encontrados construyendo un pipeline de verdad en este
mismo servidor, con el razonamiento que llevó a cada solución — porque el razonamiento
es la parte reutilizable, no la solución específica.

## 1. Un nodo de cómputo sin un software requerido, en silencio

**Síntoma:** un pipeline que repartía ~550 trabajos casi idénticos entre varios nodos
de cómputo corrió bien durante las primeras cientas, luego empezó a fallar con
`apptainer: No such file or directory` (código de salida 127) en un subconjunto de
tareas, sin un patrón obvio solo a partir del mensaje de error.

**Instinto equivocado:** simplemente reintentar las tareas fallidas y esperar que
haya sido algo pasajero.

**Lo que realmente funcionó:** enviar unos pocos trabajos de diagnóstico pequeños,
cada uno fijado exactamente a un nodo candidato (`host=pneN`), cada uno revisando
solamente `ls /usr/bin/apptainer`. Esto aisló el problema a un único nodo que, por
alguna razón, no tenía el binario de Apptainer en absoluto — todos los demás nodos sí
lo tenían.

**La solución:** dado que esta configuración de PBS no admite *excluir* un nodo
(`host!=pneN` falla directamente), la solución fue listar explícitamente los nodos
buenos conocidos y alternar entre ellos en round-robin:

```groovy
// ejemplo: dentro del clusterOptions de un process de Nextflow
def good_nodes = ['pne3', 'pne4', 'pne6', 'pne7', 'pne10']
clusterOptions { "-l select=1:ncpus=2:mem=4gb:host=${good_nodes[task.index % good_nodes.size()]}" }
```

**La lección:** cuando un lote de trabajos falla de forma inconsistente (algunos
nodos sí, otros no), no adivines ni reintentes — escribe la reproducción más pequeña
posible (un trabajo, un nodo, una revisión) para cada sospechoso y deja que la
evidencia te diga cuál es.

## 2. Un contenedor no puede ver un archivo que está justo ahí

**Síntoma:** un trabajo llamando a
`apptainer exec algunaherramienta.sif ... /data2/ruta/a/entrada.gff` falló con
`FileNotFoundError`, aunque `cat /data2/ruta/a/entrada.gff` desde un shell interactivo
funcionaba perfectamente, y el archivo estaba confirmado como existente con `ls`.

**Instinto equivocado:** asumir que el paso anterior de copia/transferencia de
archivos en el pipeline había quedado incompleto o corrupto de alguna forma, y
volverlo a ejecutar.

**Lo que realmente funcionó:** leer el código fuente de la propia herramienta que
fallaba (es de código abierto — el traceback apuntaba a una línea exacta) confirmó que
en efecto hacía un `open(ruta)` simple exactamente sobre la ruta que se le había
pasado. Eso descartó un bug en la herramienta misma y apuntó hacia la frontera del
contenedor: el comportamiento de montaje por defecto de Apptainer no garantiza que
rutas absolutas arbitrarias en el almacenamiento compartido sean visibles dentro del
contenedor, solo tu directorio personal y el directorio de trabajo actual.

**La solución:** hacer `cd` al directorio de trabajo del propio trabajo primero y
usar `cp` para copiar ahí las entradas necesarias, luego referenciarlas por ruta
relativa en vez de la ruta absoluta original. (Explicación completa y ejemplo en
`03_contenedores_apptainer/README.md`.)

**La lección:** "el archivo no existe" desde dentro de un trabajo en contenedor no
siempre significa que el archivo no existe — revisa si es un problema de bind mount
antes de asumir un problema de datos, especialmente si la misma ruta funciona bien
fuera del contenedor.

## 3. Una herramienta que falla con datos biológicos reales no siempre es un bug

**Síntoma:** una herramienta de análisis de pangenoma falló a mitad de un conjunto de
datos real con `ValueError: Invalid gene sequence!` en algunos de los genomas de
entrada.

**Instinto equivocado:** asumir que los archivos de entrada estaban mal formados y
empezar a rederivarlos.

**Lo que realmente funcionó:** leer la lógica de validación de la propia herramienta
mostró que estaba rechazando genes con codones de paro internos, longitudes que no
eran múltiplos de 3, o corrimientos de marco de lectura — exactamente el tipo de
anotación que se esperaría de pseudogenes reales en un genoma, no necesariamente una
señal de entrada corrupta. La propia salida de `--help` de la herramienta listaba una
opción (`--remove-invalid-genes`) específicamente para esta situación.

**La solución:** usar la opción que la propia herramienta ofrece para esto — existe
porque los datos biológicos reales legítimamente contienen esto, no como un parche
para un bug de datos.

**La lección:** antes de asumir que tu entrada está rota, revisa si la herramienta
tiene una opción documentada exactamente para la falla que estás viendo — una opción
hecha específicamente para eso es una señal mucho más fuerte de que la falla es
esperada, y no un bug, que un `try/except` genérico.

## 4. Nunca, ni siquiera brevemente, hacer cómputo en el nodo de acceso

**Síntoma:** ninguno, en realidad — esta es una nota de disciplina, no una historia
de depuración. Pero vale la pena decirlo claramente: es muy fácil, en medio de una
sesión de depuración, ejecutar "solo un comando rápido" directamente por SSH en el
nodo de acceso en vez de envolverlo en un trabajo PBS, especialmente para algo que se
siente trivialmente barato (revisar la salida `--help` de una herramienta, por
ejemplo). Esto pasó una vez mientras se construía el pipeline del cual sale esta
guía — detectado en menos de un minuto, se mató el proceso perdido, sin daño
duradero, pero no debió haber pasado en absoluto.

**El hábito a construir:** si un comando necesita ejecutar *cualquier cosa* más allá
de un script de shell trivial (cualquier programa real, cualquier contenedor,
cualquier cómputo de verdad), pasa por `qsub`, punto final — incluso para algo que se
siente que va a tardar dos segundos. El nodo de acceso es un espacio de orquestación
compartido por todos; trátalo así de forma constante, no solo cuando sea conveniente.
