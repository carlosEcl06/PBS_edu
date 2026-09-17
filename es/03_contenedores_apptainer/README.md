# 03 — Ejecutar software con contenedores Apptainer

Instalar herramientas de bioinformática directamente (vía `conda`, `pip`, compilando
desde el código fuente...) a menudo termina en una pelea con la resolución de
dependencias, y es fácil terminar con una versión sutilmente distinta de la
herramienta respecto a un(a) colega, lo que dificulta comparar o reproducir
resultados. La opción recomendada por defecto aquí en su lugar: ejecutar la
herramienta desde un contenedor ya construido.

## Por qué contenedores, y por qué fijar una versión exacta

[Biocontainers](https://biocontainers.pro/) publica un contenedor para prácticamente
cada herramienta común de bioinformática, construido y versionado automáticamente a
partir de Bioconda. Dos hábitos importan:

1. **Fija la etiqueta de versión exacta, no uses `:latest`.** `:latest` cambia
   silenciosamente con el tiempo y rompe la reproducibilidad -- si tus resultados
   dependen de la versión X de una herramienta y alguien vuelve a correr tu pipeline
   seis meses después con lo que `:latest` se haya vuelto para entonces, puede obtener
   números distintos sin ninguna razón obvia.
2. **Consigue la etiqueta exacta de una fuente confiable ya verificada, no adivines.**
   Una buena forma: mira cómo un framework de pipelines ya establecido
   ([nf-core/modules](https://github.com/nf-core/modules)) fija la misma herramienta —
   sus definiciones de módulo listan la cadena exacta
   `quay.io/biocontainers/<herramienta>:<versión>`, que es una fijación real y probada,
   no una suposición.

## Descargar y ejecutar un trabajo con contenedor

```bash
apptainer pull --force miherramienta.sif docker://quay.io/biocontainers/miherramienta:1.2.3--hdfd78af_2
apptainer exec miherramienta.sif miherramienta --version
```

`apptainer pull` descarga y convierte la imagen una vez; después de eso,
`apptainer exec miherramienta.sif <comando>` ejecuta cualquier cosa dentro de ella como
si estuviera instalada localmente. Haz el pull una vez (idealmente hacia
almacenamiento compartido, no algo que se vuelva a descargar en cada trabajo) y
reutiliza el archivo `.sif` entre trabajos.

## La trampa que te va a atrapar: los bind mounts

Un contenedor solo ve las partes del sistema de archivos que están explícita (o por
defecto) "montadas" (bind-mounted) dentro de él. Apptainer monta automáticamente tu
directorio personal y el directorio de trabajo actual por defecto, pero **no monta de
forma confiable rutas absolutas arbitrarias** en otro lugar del almacenamiento
compartido solo porque puedas verlas desde tu shell de acceso.

Concretamente: si el script de tu trabajo hace esto --

```bash
apptainer exec miherramienta.sif miherramienta -i /data2/projects/OTRO-PROYECTO/entrada.txt
```

-- y esa ruta no está cubierta por un montaje automático, `miherramienta` fallará con
algo como "No such file or directory" para un archivo que sin duda existe y que *tú*
puedes leer con `cat` sin problema desde el mismo shell. Esto es genuinamente confuso
la primera vez que pasa, porque el error parece un problema de archivo faltante cuando
el archivo está justo ahí.

**La solución confiable: haz `cd` al directorio de trabajo de tu propio trabajo
(dentro del área montada automáticamente) y copia ahí tus entradas primero**, luego
referéncialas con rutas relativas:

```bash
cd /data2/projects/TU-PROYECTO/results/mi_trabajo   # algún lugar donde tengas un directorio de trabajo real
cp /data2/projects/OTRO-PROYECTO/entrada.txt .
apptainer exec miherramienta.sif miherramienta -i entrada.txt   # ruta relativa, siempre funciona
```

Esto cuesta algo de I/O de disco por la copia, pero es la diferencia entre un trabajo
que funciona siempre y uno que falla misteriosamente dependiendo exactamente de qué
rutas toque.

## Pruébalo

`example_container_job.pbs` descarga un contenedor público pequeño y rápido y ejecuta
un comando trivial dentro de él — envíalo tal cual primero. Luego
`exercise_03_run_a_tool.pbs` te pide descargar el contenedor de una herramienta real
de bioinformática y revisar su versión, completando tú mismo(a) la etiqueta del
contenedor (búscala en nf-core/modules o biocontainers.pro, no adivines).
