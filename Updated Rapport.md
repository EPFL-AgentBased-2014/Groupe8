###1. Introduction et intérêt de la recherche

Le trafic ferroviaire est en général pensé et modélisé de façon top-down. Peut-on le modéliser suivant un processus bottom-up, et comment ? (C'est-à-dire, le trafic peut-il être défini en fonction des paramètres des rames elles-mêmes?)


###2. Objectifs et hypothèses

Modéliser un trafic ferroviaire (métro) de type bottom-up selon des paramètres de fréquence, vitesse, temps d'arrêt, trajet.

Hypothèse : avec un temps d'arrêt minimal à chaque station et une information en temps réel, une fréquence optimale peut être trouvée pour une certaine vitesse de circulation des rames.

But : parvenir a une configuration optimale d'un maximum de deux métros arrêtés par station. (Voire un seul métro pour certaines stations – Bassenges p.ex). 


###3. Méthodes et procédures

On modélise le m1.
	
Trois types de patchs sont crées : stations, rails, terminus. Les agents (turtles) sont les rames de métro, se déplaçant sur les patchs rails et stations.

Chaque type de patch a ses propriétés : 
 les patchs rails ne peuvent accueillir qu'un seul agent à la fois, peu importe sa direction
 les patchs stations imposent l'arrêt aux agents et peuvent accueillir un nombre illimité d'agents. 
 Les patchs terminus son des stations aux extrémités de l'espace, qui imposent aux agents de faire demi-tour afin de poursuivre leur trajet dans l'autre sens. 

Les agents ont le pouvoir de changer l'état du patch rail de « libre » à « occupé ».

Un agent ne peut quitter une station que si le patch rail sur lequel il veut se rendre est libre. 


###4. Résultats


###5. Conclusion et discussion
