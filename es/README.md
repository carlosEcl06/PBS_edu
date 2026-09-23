# PBS para bioinformática: un curso práctico

> [!NOTE]
> **Traducción en curso.** Las secciones **00** y **01** están traducidas y al día con el curso en inglés.
> Las secciones **02 a 08** de momento solo existen [en inglés](../en/README.md): los enlaces de la ruta de
> abajo llevan directamente a ellas, y puedes continuar allí con la misma configuración (ver el final de la
> [sección 01](01_pbs_basics/README.md#siguiente-paso-continuar-en-inglés)).

Aprende a ejecutar análisis reales en un cluster de cómputo compartido con PBS, haciéndolo. Cada ejercicio es un
job que envías, que corre sobre datos de secuenciación reales (o simulados de forma realista) con herramientas
reales, y que compruebas con un comprobador automático.

**Para quién es:** biólogos, estudiantes y analistas que conocen lo básico de Linux (`cd`, `ls`, `nano`) y acaban
de recibir una cuenta en un cluster.
**Qué sabrás hacer después:** escribir y enviar scripts de job, elegir CPU/memoria/tiempo con criterio, procesar
muchas muestras en paralelo, encadenar pasos en un pipeline, ejecutar herramientas desde contenedores y averiguar
por qué falló un job.
**Tiempo:** unas 6–8 horas en total; cada sección se sostiene sola (45–60 min) y se apoya en la anterior.

---

## ¿Por qué un curso? La versión de un párrafo

Un cluster lo comparte mucha gente. Entras en un **nodo de login** para preparar el trabajo y envías **jobs** a un
planificador (PBS), que los ejecuta en **nodos de cómputo** cuando hay recursos libres. Los análisis que necesitan
CPU o memoria de verdad van en jobs, nunca en el nodo de login. Esa única regla, más un puñado de comandos
(`qsub`, `qstat`, `qdel`), cubre el 90 % del uso diario. El resto del curso es el otro 10 %: hacerlo de forma
eficiente y arreglarlo cuando se rompe.

## La ruta

| # | Sección | Vas a | Datos / herramientas | Traducción |
|---|---|---|---|---|
| 00 | [Primeros pasos](00_getting_started/README.md) | conectarte, ejecutar la configuración, enviar tu primer job | referencia de SARS-CoV-2 + lecturas reales | ✅ al día |
| 01 | [Lo básico de PBS](01_pbs_basics/README.md) | escribir, enviar, seguir y depurar un job | zcat, awk | ✅ al día |
| 02 | [Contenedores](../en/02_containers/README.md) | ejecutar herramientas de bioinformática sin instalarlas | seqkit, FastQC | ⏳ solo en inglés |
| 03 | [Recursos e hilos](../en/03_resources_threads/README.md) | medir un job y pedir las CPUs, memoria y tiempo adecuados | minimap2, samtools | ⏳ solo en inglés |
| 04 | [Job arrays](../en/04_job_arrays/README.md) | un job por muestra, repetir solo los fallos | fastp, seqkit | ⏳ solo en inglés |
| 05 | [Pipelines y dependencias](../en/05_pipelines_dependencies/README.md) | encadenar QC → alineamiento → resumen | fastp, minimap2, samtools | ⏳ solo en inglés |
| 06 | [Jobs interactivos y nodos](../en/06_interactive_and_nodes/README.md) | probar en vivo en un nodo de cómputo, leer el estado de los nodos | pbsnodes | ⏳ solo en inglés |
| 07 | [Resolución de problemas](../en/07_troubleshooting/README.md) | diagnosticar seis jobs rotos | logs, qstat | ⏳ solo en inglés |
| 08 | [Nextflow](../en/08_nextflow/README.md) (opcional) | ejecutar y ampliar un pipeline de gestor de workflows | Nextflow | ⏳ solo en inglés |

Haz la 00 primero y luego la 01–05 en orden. La 06 y la 07 se pueden hacer en cualquier momento después de la 01. La 08 es opcional.

## Qué necesitas

- Una cuenta en un cluster PBS (OpenPBS o PBS Professional) y una terminal con `ssh`.
- `git` (u otra forma de copiar esta carpeta al cluster), `bash`.
- Apptainer o Singularity en el cluster (habitual en clusters académicos; el script de configuración te avisa si falta).
- Alrededor de 1 GB de disco en un directorio que vean los nodos de cómputo, y acceso a internet desde el nodo de
  login para las descargas iniciales.

**No** necesitas permisos de administrador, herramientas de bioinformática instaladas ni experiencia previa con
planificadores.

## Cómo funciona cada sección

1. Lee el `README.md` de la sección (objetivos, conceptos, tabla "si algo sale mal").
2. Ejecuta los **ejemplos** (`example_*.pbs`): funcionan tal cual. Lee sus comentarios.
3. Haz los **ejercicios**: `exercise_*.pbs` (rellenar huecos, arreglar un job roto o escribir uno desde cero).
4. Ejecuta el **comprobador** de la sección (`check_*.sh`). Inspecciona las salidas reales de tus jobs y te dice qué
   está mal y dónde mirar. Los comprobadores nunca cambian nada.
5. Compara con `solutions/` solo después de intentarlo.

**Convenciones que recordar**
- Envía los jobs **desde el directorio de la sección**: `cd 01_pbs_basics; qsub example_count_reads.pbs`.
- Las particularidades de tu cluster están en `site.conf` (lo escribe `00_getting_started/setup.sh`). Ningún
  script fija una cola, un nodo o una ruta. Mira `examples/site.pne.conf` para ver un ejemplo completo.
- `lib/edu.sh` reúne pequeñas funciones compartidas (cortas, legibles, merece la pena leerlas).
- Los logs de los jobs aparecen en el directorio de envío, con el nombre `<nombredeljob>.o<jobid>`, cuando el job termina.
- Los archivos de resultado que crean tus jobs van a `$WORKDIR` (de `site.conf`), una subcarpeta por sección.
  Dentro de cada directorio de sección, **`results/`** es un atajo a esa carpeta (se crea automáticamente):
  `ls results/`. El propio `$WORKDIR` solo está definido después de `source lib/edu.sh`.
- Los nombres de archivos y carpetas son los mismos que en la versión en inglés, para que los comandos sean
  idénticos en las dos.

## Extras

- [Chuleta](../en/CHEATSHEET.md) (en inglés): los comandos y la anatomía de un script en una página.
- [Glosario](../en/GLOSSARY.md) (en inglés): todos los términos usados, en lenguaje sencillo.

## Notas para instructores y mantenedores

- La versión en inglés (`../en/`) es la referencia; esta carpeta traduce comentarios, mensajes y textos, sin
  cambiar el comportamiento de los scripts.
- Los comprobadores calculan los valores esperados a partir de los propios datos (nada está fijado a un conjunto
  de datos).
- Datos: el genoma de referencia y los 100 pares de lecturas reales vienen de los test-datasets públicos de
  nf-core (con sumas de comprobación en `00_getting_started/data.sha256`); las muestras más grandes las simula un
  job con `wgsim`.
- Las versiones de los contenedores están fijadas en `containers.conf`.
- `../en/tests/lint.sh es` ejecuta las comprobaciones estáticas en esta carpeta (no hace falta cluster).
