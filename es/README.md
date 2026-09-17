# PBS_edu — planificación de trabajos en este clúster compartido

Una guía práctica para ejecutar trabajos de cómputo en este servidor de la forma
correcta: a través del planificador PBS, nunca en el nodo de acceso, con contenedores
fijados a versiones exactas. Los ejemplos aquí provienen de un pipeline real de
filogenómica construido en este mismo servidor — incluidos algunos problemas
encontrados en el camino.

## Por qué existe esta guía

Este es un servidor compartido, usado por varias personas al mismo tiempo. El nodo de
acceso (`pne2`) sirve para editar archivos, enviar trabajos y hacer orquestación
ligera — **no para ejecutar nada que use CPU o memoria de verdad**. Los trabajos de
todos pasan por PBS, que los distribuye entre los nodos de cómputo (`pne3` hasta
`pne10`, la disponibilidad varía). Si ejecutas tu análisis directamente en `pne2` en
lugar de enviarlo como trabajo, no solo estás rompiendo una regla — estás usando CPU
que pertenece al nodo compartido de acceso/orquestación, del cual depende todo el mundo
(incluida la gente que solo quiere hacer `cd` y revisar el estado de su trabajo).

La buena noticia: después de hacerlo dos o tres veces, enviar un trabajo PBS no es más
difícil que ejecutar un comando directamente. Esta guía te lleva hasta ahí.

## Cómo usar esta carpeta

Recorre los directorios numerados en orden. Cada uno tiene:
- un `README.md` explicando el concepto,
- uno o más **ejemplos funcionales** que puedes enviar tal cual para ver cómo es un
  trabajo real de principio a fin,
- uno o más **ejercicios** — el mismo tipo de script, pero con partes importantes en
  blanco (`___`), para que tú las completes y lo envíes por tu cuenta.

Nada aquí toca datos reales del proyecto. Cada ejercicio envía un trabajo trivial (se
ejecuta en segundos, usa recursos mínimos) para que puedas iterar rápido sin
preocuparte por consumir recursos compartidos mientras todavía estás aprendiendo.

1. **`01_basicos_pbs/`** — enviar, revisar y cancelar un trabajo. Empieza aquí incluso
   si ya usaste PBS/Slurm en otro lugar — las opciones y particularidades cambian de un
   clúster a otro.
2. **`02_seleccion_de_nodos/`** — revisar qué nodos de cómputo están realmente libres, y
   fijar tu trabajo explícitamente en uno de ellos. Importa más aquí que en algunos
   otros clústeres, por razones explicadas en esa sección.
3. **`03_contenedores_apptainer/`** — ejecutar software desde un contenedor en vez de
   pelear con la resolución de dependencias de `conda`/`module load`. Esta es la opción
   recomendada por defecto para cualquier herramienta que no sea trivial de instalar.
4. **`04_errores_comunes/`** — errores reales encontrados construyendo un pipeline de
   producción en este mismo servidor, escritos como lecciones en vez de quedar solo
   como conocimiento tácito.
5. **`05_nextflow_avanzado/`** (opcional, una vez que lo básico se sienta natural) —
   orquestar un pipeline de varias etapas (muchos trabajos, dependencias entre ellos)
   con el ejecutor PBS de Nextflow en vez de encadenar `qsub` a mano.

## La versión de un párrafo, si no lees nada más

Nunca ejecutes cómputo real en `pne2`. Antes de enviar un trabajo, revisa qué nodos de
cómputo están realmente libres (`pbsnodes <nodo>`) en vez de asumirlo — este servidor
no siempre permite excluir un nodo específico, solo fijarse *en* uno, así que si no
revisas antes puedes terminar en cola detrás del trabajo de otra persona, o asignado
silenciosamente a un nodo con un problema conocido. Prefiere contenedores Apptainer
fijados a una versión exacta en vez de `conda`/paquetes del sistema para cualquier cosa
más allá de un script de una línea. Y cuando un trabajo basado en contenedor no pueda
encontrar un archivo que sí es visible desde tu shell de acceso, verifica si la ruta
realmente está montada (bind-mount) dentro del contenedor antes de asumir que tus datos
desaparecieron — ver `04_errores_comunes/`.
