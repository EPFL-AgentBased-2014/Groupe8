###Idée :

Modéliser le déplacement de rames de métro du M1 : quelle circulation, quelle férquence, comment gérer les croisements, terminus ?


###Problématique : peut-on aboutir à un fonctionnement optimal à fréquence régulière ?
Agents et Patchs

### On cherche à comprendre comment 3 paramètres (vitesse, fréquence, temps d'arrêts) influencent la circulation du M1.

agents : rames de métro

patch : arrêts, voies bi-directionnelles aux arrêts, voies uni-directionnelles


###variables :

vitesse de l'agent rame de métro

nombre d'agents (nombre de rames de métros) -> fréquence

temps d'arrêt de l'agent sur un patch


###Pour Commencer :

Un agent (la rame) se déplace sur une ligne (patch rails) et s'arrête (patch stations).

Le patch peut être dnas deux états : occupé ou libre

L'agent peut quitter le patch station si les patchs rails sur lesquels il se rend sont LIBRES. Il rend les paths sur lesquels il passe OCCUPES.

Echelle : 1 patch - 100m par exemple
