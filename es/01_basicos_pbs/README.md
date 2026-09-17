# 01 — Fundamentos de PBS: enviar, revisar, cancelar

PBS (este clúster corre OpenPBS) planifica tu trabajo en un nodo de cómputo y lo
ejecuta ahí, en lugar de en el nodo donde estés conectado en ese momento. Un trabajo
PBS es simplemente un script de shell con unas líneas especiales de comentario `#PBS`
al inicio, indicándole al planificador qué recursos necesitas.

## Los tres comandos que usarás constantemente

```bash
qsub mi_trabajo.pbs        # envía un trabajo, imprime su ID (ej. "3120.pne2")
qstat -u $(whoami)         # lista tus trabajos y su estado
qdel 3120.pne2               # cancela un trabajo (en ejecución o en cola)
```

Estados de trabajo que verás en `qstat`: `Q` (en cola, esperando recursos), `R` (en
ejecución), y una vez que termina, el trabajo simplemente desaparece de la lista
predeterminada de `qstat` (usa `qstat -x 3120.pne2` para ver la información contable de
un trabajo terminado, o `qstat -xf` para el detalle completo, incluyendo su código de
salida).

## Anatomía de un script de trabajo mínimo

```bash
#!/bin/bash
#PBS -N mi_primer_trabajo     # un nombre para el trabajo (aparece en qstat)
#PBS -q workq                 # la cola -- workq es la estándar aquí
#PBS -l select=1:ncpus=1:mem=1gb   # 1 nodo, 1 CPU, 1GB de RAM
#PBS -l walltime=00:05:00     # mata el trabajo si sigue corriendo después de 5 minutos
#PBS -o mi_trabajo.out        # a dónde va la salida estándar (se escribe cuando termina el trabajo)
#PBS -e mi_trabajo.err        # a dónde va la salida de error

echo "Hola desde $(hostname), corriendo como trabajo $PBS_JOBID"
date
sleep 10
echo "Terminado."
```

Guarda esto como `mi_trabajo.pbs` y envíalo con `qsub mi_trabajo.pbs`. Algunas cosas que
vale la pena saber antes de hacerlo:

- **`walltime` es un límite estricto.** Si tu trabajo sigue corriendo cuando se alcanza
  ese tiempo, PBS lo mata. Deja siempre un margen real por encima de lo que esperas que
  el trabajo realmente tarde — un trabajo interrumpido a la mitad puede dejar una
  salida parcial/corrupta, que es una experiencia de depuración mucho peor que un
  trabajo que simplemente termina un poco antes.
- **`-o`/`-e` generalmente solo se escriben cuando el trabajo termina**, no en tiempo
  real, en esta configuración particular de PBS. No te alarmes si el archivo de salida
  todavía no existe mientras `qstat` muestra el trabajo como `R` — eso es normal aquí,
  no una señal de que algo esté mal.
- **El script corre en el nodo de cómputo que PBS asigne**, partiendo de donde se
  ejecutó `qsub` como contexto de directorio de trabajo (las rutas en tu script deben
  ser generalmente absolutas, o debes hacer `cd` explícitamente primero, para evitar
  ambigüedad).
- **Las líneas de directiva `#PBS` no admiten comentarios al final de línea** en esta
  configuración — `#PBS -l ncpus=2  # mi comentario` fallará con un `directive error`,
  porque el intérprete trata todo lo que sigue después de `-l` como texto de la
  directiva, no como un comentario de shell que se descarta. Pon los comentarios
  explicativos en su propia línea, arriba de la directiva. (Esto se descubrió la
  primera vez enviando realmente los scripts de ejercicio de abajo para comprobar que
  funcionaran — vale la pena hacerlo tú mismo(a) cada vez que escribas un script nuevo,
  no solo confiar en que se ve bien.)

## Pruébalo

Ejecuta primero el ejemplo funcional, tal cual, para ver el ciclo completo de
enviar → esperar → revisar:

```bash
qsub example_hello_world.pbs
qstat -u $(whoami)
# espera unos segundos, luego:
cat example_hello_world.out
```

Después abre `exercise_01_fill_in_blanks.pbs`, completa los espacios en blanco
(marcados `___`), y envía tu propia versión. Si te atoras,
`exercise_01_ANSWER.pbs` tiene una solución ya resuelta — pero inténtalo tú
mismo(a) primero, ese es el punto.
