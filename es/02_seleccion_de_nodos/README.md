# 02 — Revisar la disponibilidad de nodos y fijar tu trabajo a uno

Por defecto, PBS elige qué nodo de cómputo ejecuta tu trabajo, según lo que esté
libre. Eso suele ser suficiente. Dos situaciones en este clúster donde conviene revisar
y fijar explícitamente en vez de confiar en el comportamiento por defecto:

1. **Un nodo está ocupado por el trabajo de otra persona.** Si pides más recursos de
   los que están libres actualmente en cualquier lugar, tu trabajo se queda en cola
   (`Q`) en vez de ejecutarse, incluso si *otros* nodos están completamente inactivos —
   PBS no intenta automáticamente otro nodo a mitad de camino como sí hacen algunos
   otros planificadores. Revisar antes te evita preguntarte por qué un trabajo que
   debería tardar 5 minutos lleva una hora en cola.
2. **Un nodo específico tiene un problema conocido.** Al momento de escribir esto, uno
   de los nodos de cómputo carece de un software (Apptainer) que la mayoría de los
   pipelines reales necesitan — un trabajo que caiga ahí falla de inmediato y de forma
   confusa. Evitar ese nodo conocido como problemático evita esto.
   **Particularidad específica de este clúster:** esta configuración de PBS no admite
   *excluir* un nodo (la sintaxis `host!=pne5` falla con "Illegal attribute or resource
   value") — solo puedes fijarte *en* un nodo específico. Así que la solución es listar
   explícitamente solo los nodos buenos y elegir uno tú mismo(a).

## Revisar qué está libre

```bash
pbsnodes pne3        # reemplaza pne3 con el nombre de cualquier nodo de cómputo
```

Busca dos cosas en la salida: `state = free` (a diferencia de
`busy`/`down`/`offline`), y si hay presente una línea `jobs = ...` (si está ausente o
vacía, nada está corriendo ahí en ese momento). Un nodo puede mostrar `state = free`
mientras aún tiene algunos trabajos corriendo, si no todos sus CPUs están en uso
todavía — revisa la línea `jobs`, no solo `state`.

Para revisar varios nodos a la vez:

```bash
for n in pne3 pne4 pne6 pne7 pne10; do
    echo -n "$n: "
    pbsnodes $n | grep -i '^ *jobs' || echo 'libre'
done
```

(Pregunta a quien administre el clúster por la lista completa actual de nombres de
nodos de cómputo y cuáles, si alguno, tienen problemas conocidos en este momento — los
nombres específicos de los nodos y los problemas irán cambiando con el tiempo, esta
guía no se va a actualizar sola.)

## Fijar tu trabajo a un nodo específico

Agrega `host=<nombre_del_nodo>` dentro de la solicitud de recursos `select`:

```bash
#PBS -l select=1:ncpus=4:mem=8gb:host=pne3
```

## Un patrón que vale la pena conocer: round-robin entre varios nodos buenos

Si estás enviando muchos trabajos pequeños e independientes (común con herramientas
como Nextflow, que reparten un pipeline en muchas tareas paralelas), fijar todos al
*mismo* nodo desperdicia los otros que están libres. Un round-robin simple —
recorriendo una lista de nodos conocidos como buenos según el índice de la tarea —
distribuye la carga sin depender de la colocación automática del propio PBS (que, en
esta configuración, a veces no es confiable). Ver `05_nextflow_avanzado/` para un
ejemplo real de este patrón en una directiva `clusterOptions` de Nextflow.

## Pruébalo

`check_free_nodes.sh` es una versión lista para ejecutar del bucle de arriba —
pruébalo ahora para ver el estado actual del clúster. Luego haz
`exercise_02_pin_to_free_node.pbs`: revisa tú mismo(a) qué nodos están libres, completa
el nombre del nodo, y envíalo.
