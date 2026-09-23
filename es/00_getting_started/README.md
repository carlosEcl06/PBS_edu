# 00 · Primeros pasos

**Vas a aprender:** qué es un cluster, cómo poner en marcha este curso en el tuyo y cómo demostrar que funciona.
**Tiempo:** 20–30 minutos (la mayor parte esperando descargas y un job pequeño).
**Necesitas:** una cuenta en un cluster PBS y una terminal. Nociones básicas de shell (`cd`, `ls`, `cat`, editar un archivo con `nano` o `vim`).

---

## 1. El modelo mental en 2 minutos

Un **cluster** es un grupo de ordenadores ("**nodos**") que comparten almacenamiento, gestionados por un **planificador**. PBS es ese planificador.

```
   tú ──ssh──▶  nodo de login ──qsub──▶  planificador (PBS) ──▶ nodo de cómputo 1
                (compartido, solo                          ├─▶ nodo de cómputo 2
                 trabajo ligero)                           └─▶ nodo de cómputo …
                        └──── sistema de archivos compartido: todos ven los mismos archivos ────┘
```

| Lugar | Qué haces ahí | Qué no debes hacer ahí |
|---|---|---|
| **Nodo de login** | entrar, editar archivos, enviar y seguir jobs, mover datos | ejecutar análisis. Lo comparte todo el mundo; un comando pesado ralentiza a todos tus compañeros |
| **Nodos de cómputo** | aquí corren los *jobs*, lanzados por PBS para ti | entrar directamente (llegas a ellos a través de PBS) |

Un **job** es solo un script de shell más una petición: *"dame 4 CPUs y 8 GB de memoria durante un máximo de 2 horas y ejecuta esto."* PBS pone la petición en cola, encuentra un nodo con espacio, ejecuta ahí el script y guarda su salida. Esa es toda la idea; el resto del curso es detalle encima de eso.

**Por qué la bioinformática lo necesita:** alinear 100 muestras, o una muestra contra un genoma grande, exige más CPUs y memoria de las que tiene un portátil, y quieres que siga corriendo después de cerrar el portátil.

## 2. Conectarse y obtener el material

```bash
ssh <tu-usuario>@<direccion-del-nodo-de-login>   # pide la dirección a la administración del cluster
git clone <url-de-este-repositorio> PBS_edu      # o copia la carpeta con: scp -r PBS_edu <tu>@<nodo-de-login>:~/
cd PBS_edu/es
```

Mover archivos entre tu portátil y el cluster:

```bash
scp results.tsv <tu>@<nodo-de-login>:~/                 # portátil -> cluster
rsync -avP <tu>@<nodo-de-login>:~/results/ ./results/   # cluster -> portátil, reanudable
```

## 3. Configuración (tres comandos y un job)

Ejecútalos desde `00_getting_started/`:

```bash
./setup.sh              # 1. descubre tu cola, la herramienta de contenedores y pregunta dónde guardar los datos
./fetch_data.sh         # 2. descarga un conjunto de datos real diminuto (unos 60 KB)
./pull_containers.sh    # 3. descarga las herramientas de bioinformática como imágenes de contenedor (unos minutos)
qsub make_samples.pbs   # 4. TU PRIMER JOB: simula 6 muestras de lecturas de secuenciación
```

`qsub` imprime un **id de job** como `12345.miservidor`. Síguelo con `qstat -u $USER`: el estado `Q` (en cola) pasa a `R` (corriendo) y luego desaparece (terminado). Tarda uno o dos minutos. Después:

```bash
./check_env.sh          # lo comprueba todo, incluido un job de prueba de 10 segundos en un nodo de cómputo
```

Al final quieres ver `Todas las comprobaciones pasaron.`

### ¿Qué hicieron esos comandos?

- **`setup.sh`** escribió `../site.conf`: un archivo pequeño con las particularidades de tu cluster (nombre de la cola, dónde están los datos, si la herramienta es `apptainer` o `singularity`). Todos los scripts del curso lo leen, así que *nada en los ejercicios está atado a un cluster concreto*. Ábrelo y léelo.
- **`fetch_data.sh`** descargó un genoma de SARS-CoV-2 de 29,8 kb y 100 pares de lecturas reales. Diminutos a propósito: las secciones 01 y 02 terminan en segundos.
- **`pull_containers.sh`** descargó las herramientas (seqkit, FastQC, fastp, minimap2, samtools, wgsim) como **imágenes de contenedor**. Un contenedor empaqueta un programa con todo lo que necesita, así que no hay nada que instalar y todo el mundo usa versiones idénticas. La sección 02 lo explica bien.
- **`make_samples.pbs`** es un job de verdad: ejecuta `wgsim` para simular 6 muestras × 300.000 pares de lecturas. Las secciones 03–05 las usan porque son lo bastante grandes para que CPU, memoria y tiempo se noten.

### Dónde acaban las cosas

- Los **logs** de tus jobs (`make_samples.o12345`): en el directorio desde el que enviaste.
- **Datos, imágenes, resultados:** en los directorios definidos en `site.conf` (`DATA_DIR`, `SIF_CACHE`, `WORKDIR`). Para usar esos nombres en tu propio shell, carga antes el archivo de funciones: `source ../lib/edu.sh; echo $DATA_DIR`.
- En todas las secciones siguientes, `results/` dentro del directorio de la sección es un atajo a su carpeta de salida.

## 4. FASTQ en 60 segundos

Los secuenciadores producen archivos **FASTQ**: 4 líneas por lectura.

```
@read_1              <- nombre
GATTTGGGGTTCAAAGCAG  <- la secuencia de ADN
+
IIIIIIIIIIIIIIIIIII  <- una puntuación de calidad por base (I = muy buena)
```

La secuenciación paired-end da dos archivos por muestra (`_R1`, `_R2`); la lectura *n* de uno va en pareja con la lectura *n* del otro. `.gz` significa comprimido con gzip; léelo con `zcat archivo.fastq.gz | head`. Un **genoma de referencia** es un archivo FASTA (una línea `>nombre` y luego la secuencia). *Alinear* lecturas contra una referencia (sección 03) es el paso pesado clásico que justifica usar clusters.

## Si algo sale mal

| Síntoma | Causa probable y solución |
|---|---|
| `qsub: command not found` | No estás en el nodo de login, o PBS necesita `module load`. Pregunta a la administración / prueba `module avail pbs`. |
| `qsub: ... queue ... required` o "no default queue" | Pon el nombre de la cola en `EDU_QUEUE` en `site.conf` (`qstat -Q` lista las colas) y usa `edu_qsub` o `qsub -q <cola>`. |
| `apptainer: command not found` | Prueba `module avail apptainer` (o `singularity`) y haz `module load`; o ejecuta `pull_containers.sh` como job (`qsub pull_containers.sh`). |
| La descarga de la imagen falla / se agota el tiempo | Puede que el nodo no tenga internet o necesite un proxy. Pregunta a la administración; las imágenes se pueden descargar en otro sitio y copiar a `sif/` como `<herramienta>.sif`. |
| El job `make_samples` se queda en `Q` | El cluster está ocupado. `qstat -f <jobid> \| grep -i comment` dice por qué. |
| `check_env.sh` dice que el job de prueba falló | Lee el log que imprime. Causa típica: `DATA_DIR` está en un disco que los nodos de cómputo no ven. Vuelve a ejecutar `setup.sh` con un directorio compartido. |
| `No space left` / errores de cuota | Apunta la configuración a un área más grande, o baja `READS_PER_SAMPLE` en `site.conf`. |

¿Listo? Ve a [01 · Lo básico de PBS](../01_pbs_basics/README.md). ¿Te atascas con una palabra? Mira el [glosario](../../en/GLOSSARY.md) (en inglés).
