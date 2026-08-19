# stabilize_leap_of_faith_anomaly

Fuegt eine dreistufige Forschungskette hinzu, ueber die **Boso Ta** (aus dem **Northriver Plot**, Story des DLCs **"Tides of Avarice"** / **"Gezeiten der Habgier"**, Erweiterungs-ID `ego_dlc_pirate`) die Anomalie zwischen Habgier und Glaubenssprung Schritt fuer Schritt stabilisiert - von "nur die einzigartige Astrid kommt sicher durch" bis zu "jedes Schiff kommt dauerhaft sicher durch".

Hintergrund zur Anomalie:

- Im Original-Skript `Setup_DLC_Pirate.xml` ist die Verbindung Glaubenssprung -> Habgier (`S3_anomaly_01` -> `S2B_anomaly_01`) bereits dauerhaft gesetzt.
- Die Gegenrichtung Habgier -> Glaubenssprung (`S2B_anomaly_01` -> `S3_anomaly_01`) wird von den Cues `TheWave_Anomaly_Activate` / `TheWave_Anomaly_Deactivate` nur waehrend der aktiven "Wave"-Phase des Systems gesetzt bzw. wieder entfernt.
- Wichtig: Die stabilisierte Anomalie liegt laut Spieldaten (`libraries/god.xml`, `maps/xu_ep2_universe/dlc_pirate_clusters.xml`) tatsaechlich in **Habgier V Dead End** (`Cluster_500_Sector002`), nicht in Habgier IV (`Cluster_500_Sector003`, hat eine eigene, unabhaengige Anomalie `S2C_anomaly_01`).
- `add_anomaly_destination` fuegt ein Ziel nur zur Menge der moeglichen Ziele einer Anomalie hinzu - laut Schema-Dokumentation wird "the destination... picked at random on transition", falls mehrere Ziele existieren. Dieses Mod nutzt das bewusst aus, statt es zu unterbinden: Sobald Forschung 1 abgeschlossen ist, ist die Verbindung fuer ALLE Schiffe grundsaetzlich moeglich (Zufalls-Ziel), aber nur die jeweils "freigeschalteten" Schiffe werden per Korrektur garantiert richtig hingeleitet (siehe unten).

## Die drei Forschungen

**Ship-Referenzen:**
- Astrid-Klasse: Macro `ship_gen_m_yacht_01_a_macro` (die einzigartige Yacht der Northriver-Zwillinge, Schiffsname "Astrid", `{20101,120101}`, vom Spieler nach bestimmten Northriver-Plot-Ausgaengen kaeuflich).
- Neuer Antriebsmod: `mod_engine_stableanomaly_01` ("Stabilisierender Antriebsregler"), geprueft am Schiff ueber `<check_object object="..."><match_engine_mod ware="ware.mod_engine_stableanomaly_01"/></check_object>` (die dedizierte Ausruestungsmod-Pruefung aus `common.xsd` - es gibt keine einfache `.mods`-Eigenschaft auf Schiffsobjekten).

**Korrektur-Warp**: Alle Korrekturen (Tier 1/2/3) laufen ueber die gemeinsame Bibliotheks-Cue `Lib_CorrectShipToDestination`, die den Sicherheitsabstand (`safepos min/max`) je nach Schiffsklasse (XS/S/M/L/XL, ueber `$Ship.class == class.ship_xs/s/m/l/xl`) skaliert - ein groesseres Schiff braucht mehr Abstand zur Anomalie. Nur der M-Wert wurde tatsaechlich im Spiel getestet, die uebrigen Stufen sind proportional dazu geschaetzt.

| # | Name | Vorbedingung | Effekt nach Abschluss |
|---|------|--------------|------------------------|
| 1 | Anomalie-Navigationsmuster: Astrid | Northriver Plot abgeschlossen **und 2** erfolgreiche, unbegleitete Spruenge Habgier -> Glaubenssprung mit einer spielereigenen Astrid (normalerweise nur waehrend eines aktiven Wave-Fensters moeglich) | Verbindung wird dauerhaft gesetzt (`Lib_StabilizeLeapOfFaithAnomaly`); **nur Astrid-Schiffe** werden bei falscher Zufalls-Landung sofort korrigiert |
| 2 | Anomalie-Stabilisierungsantrieb | Forschung 1 abgeschlossen **und 3 weitere** erfolgreiche (jetzt stabile) Astrid-Spruenge | Neuer Antriebsmod "Stabilisierender Antriebsregler" wird craftbar; **Astrid + Schiffe mit diesem Mod** werden korrigiert |
| 3 | Anomalie stabilisieren | Forschung 2 abgeschlossen **und 5** erfolgreiche Spruenge mit einem modifizierten (nicht-Astrid) Schiff | **Jedes Schiff** wird bei falscher Zufalls-Landung korrigiert - echte, universelle, dauerhafte Stabilisierung |

Jede Forschung wird erst per `add_encyclopedia_entry` im Forschungsbaum sichtbar, sobald ihre Vorbedingung erfuellt ist, begleitet von einer Boso-Ta-Nachricht ("Eine stabile Verbindung?" / "Auf Erfolg aufbauen" / "Das fehlende Puzzleteil").

## Wie die Erfolgs-Vorbedingungen erkannt werden

Ueber `event_object_entered_anomaly` (Attribute `entry`/`exit` zum Filtern nach genau unserer Anomalie, `event.object` = eintretendes Schiff, `event.param2` = tatsaechlich gewaehltes Ausgangs-Ziel). Jede Vorbedingung ist ein eigener, nicht-instanzierter Cue (`StabilizeLeapOfFaithAnomaly_Achievement1/2/3`) mit genau diesem (potenziell oft wiederkehrenden) Event als Bedingung und einem eigenen `$JumpCount`: Trifft die gewuenschte Kombination (Schiffstyp/Mod, spielereigen, richtiges Ziel erreicht) bei einem konkreten Durchflug zu, wird `$JumpCount` per `operation="add"` um 1 erhoeht. Ist der jeweilige Schwellenwert (2 / 3 / 5) noch nicht erreicht, setzt sich der Cue per `reset_cue` zurueck und wartet auf den naechsten Durchflug - `$JumpCount` bleibt dabei erhalten (bestaetigtes Vanilla-Muster: `lib_dialog.xml`s `$CurrentActor operation="add"` + `reset_cue cue="this"`, bzw. `rml_race_timetrial.xml`s `$CurrentLap operation="add"` - beide akkumulieren genauso ueber Resets hinweg). Ist der Schwellenwert erreicht, bleibt der Cue "complete" und schaltet (per `check_any` aus `check_value`-Zustandspruefung + `event_cue_completed`, fuer Speicherstand-Kompatibilitaet) die jeweils naechste Forschung frei.

Die Vorbedingung fuer Forschung 1 ist bewusst NICHT an unser eigenes Mod gebunden: Die Spruenge muessen dabei bereits ganz ohne unser Zutun ueber die normale, temporaere Verbindung waehrend eines "Wave"-Fensters gelingen. Der Spieler muss dabei nicht selbst am Steuer sitzen - jedes spielereigene Schiff (`event.object.isplayerowned`) zaehlt, auch wenn es z. B. im Auftrag unterwegs ist.

## Wie die dauerhafte Stabilisierung tatsaechlich aufrechterhalten wird

Das Original-Skript entfernt die Habgier -> Glaubenssprung-Verbindung am Ende jedes Wave-Fensters wieder (`Setup_DLC_Pirate.TheWave_Anomaly_Deactivate`, ruft `remove_anomaly_destination` auf). Ein reiner Timer-basierter "Keepalive" (z. B. alle 30-60s neu setzen) wuerde dabei eine Luecke von bis zu 60 Sekunden zwischen dem Entfernen durch das Original-Skript und der naechsten eigenen Neuanwendung offenlassen - in dieser Zeit waere die Verbindung tatsaechlich unterbrochen. Deshalb reagiert `StabilizeLeapOfFaithAnomaly_ReactToWaveDeactivate` direkt auf genau dieses Deaktivierungs-Event und stellt die Verbindung sofort wieder her (Luecke praktisch null). Der Timer-basierte `StabilizeLeapOfFaithAnomaly_Keepalive` (30-60s) bleibt zusaetzlich als Sicherheitsnetz bestehen, falls das Event z. B. durch einen mitten in der Luecke geladenen Spielstand oder eine spaetere Aenderung am Original-Skript einmal nicht greift. Aktiv (und damit auch die komplette Forschungskette 2/3) erst ab Abschluss von Forschung 1.

## Voraussetzung fuer die gesamte Kette: Northriver Plot abgeschlossen

```
md.Story_Thefan.Ch10_Epilogue.exists and
  (md.Story_Thefan.Ch10_Epilogue.state == cuestate.complete or
   md.Story_Thefan.Ch10_Epilogue.state == cuestate.cancelled)
```

`Story_Thefan` ist Egosofts interner Datei-/Skriptname fuer den Northriver Plot, `Ch10_Epilogue` die letzte Kapitel-Cue der Story.

**Warum `complete ODER cancelled`, nicht nur `complete`**: `Ch10_Finished` (die naheliegendere Cue) ist keine zuverlaessige "Story fertig"-Pruefung - `story_thefan.xml` enthaelt `<patch sinceversion="2"/"3" state="cancelled">`-Bloecke fuer genau diese Cue, d. h. es ist ein bekanntes, erwartetes Verhalten, dass sie bei Spielern, die die Story reell abgeschlossen haben, trotzdem im Zustand "cancelled" statt "complete" landet (live durch Diagnose-Tests bestaetigt). Egosoft selbst behandelt genau diese Mehrdeutigkeit an anderer Stelle (`story_thefan.xml`, Cue `Ch10_DisengageVig_v2`) mit exakt derselben Pruefung - nur auf `Ch10_Epilogue` statt `Ch10_Finished`, weshalb dieses Mod ebenfalls `Ch10_Epilogue` verwendet.

**Warum der uebergeordnete `StabilizeLeapOfFaithAnomaly_Init`-Cue nur ein Event traegt (kein `checkinterval`)**: Ein Cue, der `checkinterval` UND ein echtes Event (`event_cue_signalled`) gleichzeitig traegt, wertet die Bedingungen laut Live-Tests nicht zuverlaessig aus. Die sichere, auch von Egosoft verwendete Variante (z. B. `RM_Warp_HQ_Wait` in `x4ep1_mentor_subscription.xml`) trennt das: ein aeusserer Cue reagiert nur auf das Event, verschachtelte Kind-Cues (z. B. `..._Research1_Complete`, `..._Research2_Complete`, `..._Research3_Complete`) pollen jeweils nur per `checkinterval`. `md.Setup.Start` ist Egosofts eigener, generischer Hook fuer "einmal ausfuehren, egal ob neues Spiel oder ein Spielstand, in dem diese Erweiterung neu aktiv wurde" (Kommentar wortwoertlich aus `md/setup.xml`) - der richtige Trigger hierfuer, da `event_universe_generated` bei einem bereits laufenden, geladenen Spielstand nie feuert (nur bei einer komplett neuen Galaxie-Erzeugung).

## Entwicklungshinweis: `create_mission` verworfen

Eine fruehere Version dieses Mods bildete den Ablauf als richtige Mission ab (`create_mission` + mehrere Missionsschritte: Protectyon Shield Generator bauen, HQ nach Habgier V Dead End verlegen, dann erforschen). Das wurde verworfen, nachdem `create_mission` im Testspielstand des Nutzers - selbst mit exakt den Attributen echter Vanilla-Missionen und in einem komplett neuen Testspiel - durchgehend keine sichtbare Mission erzeugte (die per `cue`-Attribut zugewiesene Ausgabevariable blieb undefiniert, ganz ohne Skriptfehler). Die Ursache blieb ungeklärt (vermutlich Interaktion mit einer der ueber 40 anderen aktiven Erweiterungen). Die jetzige Loesung (Nachrichten + direkt sichtbare Forschungen, ganz ohne Missionsobjekt) umgeht das Problem vollstaendig.

## Technische Hinweise

- MD-Skript: `src/md/stabilize_leap_of_faith_anomaly.xml`.
- Neue Forschungswaren + Antriebsmod: `src/libraries/wares.xml` (Diff-Patch, fuegt `research_stabilize_leap_of_faith_anomaly_1/2/3` und `mod_engine_stableanomaly_01` hinzu, alle mit `tags="research"` bzw. `tags="crafting equipmentmod"` - **kein** `hidden`-Tag bei den Forschungen, da dieses eine Forschung unabhaengig vom Encyclopedia-Status dauerhaft ausblendet, live bestaetigt).
- Neuer Ausruestungsmod-Eintrag: `src/libraries/equipmentmods.xml` (Diff-Patch, registriert `mod_engine_stableanomaly_01` als Antriebsmod mit leichtem Boost-Thrust-Bonus).
- Eigene Texte (Forschungsnamen/-beschreibungen, Mod-Name/-beschreibung, Boso-Ta-Nachrichten) unter einer eigenen, kollisionsfreien Textseite `9000001`: `src/t/0001-l044.xml` (Englisch), `src/t/0001-l049.xml` (Deutsch).
- Keine Aenderung an Original-Dateien des DLCs.
- Benoetigt DLC "Tides of Avarice" / "Gezeiten der Habgier" (`ego_dlc_pirate`), siehe `content.xml`.
