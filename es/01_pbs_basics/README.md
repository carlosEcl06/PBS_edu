# 01 · Lo básico de PBS

**Vas a aprender:** escribir, enviar, seguir y depurar un job.
**Tiempo:** 45 minutos.
**Antes de empezar:** terminaste [00 · Primeros pasos](../00_getting_started/README.md) (`check_env.sh` pasa).
**Por qué importa en bioinformática:** cada paso posterior, sea trimming, alineamiento o llamada de variantes, es "un script más una petición de recursos". Domina esto y el resto es solo cambiar el comando de dentro.

> **Convención usada en todo el curso:** envía los jobs *desde el directorio de la sección* (`cd 01_pbs_basics; qsub algo.pbs`). Los scripts usan `source ../lib/edu.sh` y lo encuentran a través del directorio desde el que enviaste.

---

## 1. Anatomía de un script de job

Un script de job es un script de shell normal con unas líneas de comentario especiales arriba que empiezan por `#PBS`. `qsub` las lee como opciones; el shell las ignora como comentarios.

```bash
#!/bin/bash
#PBS -N count_reads
#PBS -l select=1:ncpus=1:mem=1gb
#PBS -l walltime=00:05:00
#PBS -j oe

cd "$PBS_O_WORKDIR" || exit 1
echo "hello from $(hostname)"
```

| Línea | Significado |
|---|---|
| `-N count_reads` | **nombre** del job, se muestra en `qstat` y se usa para los nombres de los archivos de log. Empieza por letra, sin espacios. |
| `-l select=1:ncpus=1:mem=1gb` | la **petición de recursos**: 1 *chunk* (un paquete de recursos colocado en un solo nodo) con 1 núcleo de CPU y 1 GB de memoria. |
| `-l walltime=00:05:00` | tiempo máximo de ejecución, `HH:MM:SS`. **PBS mata el job cuando se agota**, esté haciendo lo que esté haciendo. |
| `-j oe` | **j**unta stderr (**e**) con stdout (**o**): un archivo de log en vez de dos. |
| `cd "$PBS_O_WORKDIR"` | los jobs **empiezan en tu home**, no donde ejecutaste `qsub`. Esta línea vuelve allí. Olvidarla es el primer error clásico. |

Opcionales pero útiles: `-o <archivo>` / `-e <archivo>` ponen nombre a los archivos de log (por defecto: `<nombre>.o<jobid>` y `<nombre>.e<jobid>`, creados en el directorio desde el que enviaste).

**Comentarios en las líneas `#PBS`:** ponlos en su propia línea, nunca detrás de la opción (`#PBS -N x   # mi job`). Algunas versiones de PBS leen el resto de la línea como parte de la opción y fallan de formas confusas. Todos los scripts de aquí siguen esa regla.

**Elegir los números:** no adivines a lo loco. Pide un poco más de lo que el job necesita: poco y lo matan; mucho y espera más en la cola y desperdicia recursos compartidos. La sección 03 enseña a medir.

## 2. Enviar y vigilar

```bash
qsub example_hello_world.pbs      # imprime un id de job, p. ej. 12345.miservidor
qstat -u $USER                    # tus jobs. Mira la columna S (estado)
qstat -f 12345                    # todo sobre un job
qdel 12345                        # cancelarlo
qstat -x -u $USER                 # incluye los jobs TERMINADOS (si el sitio guarda historial)
qstat -xf 12345                   # detalles completos de un job terminado: Exit_status, resources_used
```

Estados: **Q** en cola · **R** corriendo · **H** retenido · **E** saliendo · **F** terminado (solo visible con `-x`).

Cuando el job termina, PBS escribe `hello.o12345` en tu directorio de envío. Léelo con `cat`. **El log solo aparece cuando el job termina**, no mientras corre, así que el archivo `.o` de un job en marcha puede no existir todavía. Es normal. Para jobs largos, escribe el progreso en tu propio archivo de log en el sistema de archivos compartido.

> **¿Adónde van mis archivos de salida?** A dos sitios distintos, a propósito:
> - el **log** (`count_reads.o12345`) lo escribe PBS en el directorio desde el que enviaste;
> - los **archivos de resultado** que crea tu script van a tu área de salida, `$WORKDIR` de `site.conf`, en una subcarpeta por sección. Dentro de cada directorio de sección, **`results/`** es un atajo a esa carpeta (se crea la primera vez que corre un job o un comprobador): `ls results/`, `cat results/fastq_counts.tsv`.
>
> ¿Quieres la ruta real? `source ../lib/edu.sh; echo $WORKDIR`. (`$WORKDIR` no está definido en tu shell de login hasta que haces `source` de ese archivo.)

## 3. Pruébalo

```bash
cd 01_pbs_basics
qsub example_hello_world.pbs
qstat -u $USER            # repite hasta que el job desaparezca
cat hello.o*              # fíjate en "Directorio al empezar el job"
qsub example_count_reads.pbs
```

`example_hello_world.pbs` muestra dónde empezó el job (¡en tu home!) y adónde fue después del `cd`. `example_count_reads.pbs` es tu primer job de bioinformática: cuenta lecturas y bases en los dos archivos FASTQ reales usando `zcat` y `awk`. Léelo y luego mira su resultado: la tabla también se guarda en un archivo, `results/fastq_counts.tsv` (ver el recuadro de arriba: `results/` es adonde van los archivos de salida de todos tus jobs).

**Preguntas para responder a partir de los logs** (no hace falta apuntarlas en ningún sitio):
1. ¿En qué nodo corrió tu job? ¿Es el nodo de login?
2. ¿Qué dijo `qstat -xf <jobid>` sobre `Exit_status`, `resources_used.walltime` y `resources_used.mem`?
3. ¿Cuántas CPUs cree el job que tiene? (`NCPUS`)

## 4. Ejercicios

Cada ejercicio tiene un **comprobador** que mira la salida real de tu job y te dice qué está mal. Las soluciones están en `solutions/`: échales un vistazo solo después de intentarlo.

### 1a · Rellena los huecos (10 min)
Edita `exercise_01a_fill_in_blanks.pbs` sustituyendo cada `___`. Envíalo, espera a que termine y ejecuta `./check_01a.sh`.

### 1b · Arregla el job roto (15 min)
`exercise_01b_fix_the_job.pbs` tiene tres bugs independientes que aparecen uno detrás de otro: uno al enviarlo, uno cuando el job empieza, uno mientras corre. Envíalo, lee qué salió mal, corrige un bug, repite. Luego `./check_01b.sh`.

### 1c · Escribe un job desde cero (15 min)
Escribe tú mismo `my_reference_stats.pbs`. Requisitos:

- 1 CPU, 1 GB, 5 minutos, un nombre a tu elección, logs unidos.
- Lee `$DATA_DIR/ref/genome.fasta` (el genoma de referencia) y escribe `reference_stats.txt` en `$WORKDIR/01_pbs_basics/` (es decir, `results/` desde este directorio) con exactamente estas cinco líneas (las claves se quedan en inglés: es lo que busca el comprobador):

  ```
  sequences: <número de registros FASTA>
  length: <número total de bases>
  gc_percent: <porcentaje de G y C, 2 decimales>
  job_id: <$PBS_JOBID>
  host: <salida de hostname, desde dentro del job>
  ```
- Pista: las líneas de cabecera empiezan por `>`; `awk` sabe contar caracteres; `gsub(/[GC]/, "")` devuelve cuántos reemplazó. `printf "%.2f"` imprime dos decimales.

Luego `./check_01c.sh`. El contenido GC es una métrica real: varía entre organismos y ayuda a detectar contaminación.

## Compruébate

Has terminado cuando puedas responder "sí" a todo esto:
- [ ] Sé explicar por qué mi job necesita `cd "$PBS_O_WORKDIR"`.
- [ ] Sé qué pasa cuando un job supera su walltime, y dónde verlo (`Exit_status`).
- [ ] Sé encontrar el log de un job terminado y el nodo en que corrió.
- [ ] `check_01a.sh`, `check_01b.sh`, `check_01c.sh` pasan.

## Si algo sale mal

| Qué ves | Qué hacer |
|---|---|
| `qsub: Unknown resource ...` / `Illegal attribute or resource value` | Una línea `#PBS` tiene una errata (`ncpu` en lugar de `ncpus`, falta el `gb`, hueco dejado como `___`). |
| El job se queda en `Q` mucho tiempo | El cluster está ocupado o pediste más de lo que tiene cualquier nodo. `qstat -f <id> \| grep -i comment`. |
| Todavía no hay archivo `.o` y el job está en `R` | Esperado: aparece al final. |
| El log dice `No such file or directory` para `../lib/edu.sh` | Olvidaste el `cd "$PBS_O_WORKDIR"`, o enviaste desde un directorio distinto al de la sección. |
| El log se corta de golpe, `Exit_status = 271` | Matado por PBS, casi seguro por superar el walltime. |
| El job terminó pero faltan los archivos de resultado | Lee el log hasta el final; probablemente el script falló a mitad. |

## Siguiente paso: continuar en inglés

Las secciones 02 a 08 todavía no están traducidas. Puedes seguir en la versión en inglés reutilizando todo lo que ya configuraste (datos, imágenes y resultados se quedan donde están, porque `site.conf` guarda rutas absolutas). Desde la carpeta `es/`:

```bash
cp site.conf ../en/site.conf
cd ../en/02_containers
```

Siguiente: [02 · Containers](../../en/02_containers/README.md) (en inglés)
