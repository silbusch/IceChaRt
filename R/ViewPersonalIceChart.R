# Plotfunktion schreiben, die user die möglichkeit gibt, eine Liste der zu visualisierenden Polygonen
# übergibt, und das entsprechende Tif, z.B. das RGB, und Icechart als funktionsparameter.
# Um rechenleistung zu sparen, wird das Tif dann nicht zugeschnitten, sondern als unterste ebene erzeugt. Darüber wird
# das Ice chart geplottet, dessen Polygone alle komplett weiß sind, außer jene, deren ID im funktionsaufruf übergeben wurde, diese
# sind durchsichtig, sodass das Tif darunter zu sehen ist. Zudem könnten die Landpolygone auch anders gefärbt werden. dann soll der user
# noch einen Titel und subtitel übergeben könnte. UNd es soll untrhalb des Plots der Text zur beschreibung der Polygonen erzeugt werden.
# aber das mit dem text nur vielleicht?
