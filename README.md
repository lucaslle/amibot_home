# amibot_home

Télécommande mobile (Flutter) pour un aspirateur robot **Amibot Spirit H2O**, pilotée via le cloud **Tuya**, utilisable depuis n'importe où (Wi-Fi, 4G, 5G).

## Contexte

- Les applications officielles fonctionnent mal : l'app Amibot a été abandonnée, et l'app de remplacement conseillée par Amibot (**Bona Robot**) n'est plus sur le Play Store.
- Hypothèse de travail : le robot embarque un module Wi-Fi **Tuya** (fréquent sur les robots de marque blanche). **Ce n'est pas encore confirmé** : il faut que l'app Smart Life détecte le robot (voir « Marche à suivre »).
- Si le robot n'est pas Tuya, cette app ne pourra pas le piloter en l'état (voir « Plan B »).

## Choix faits et pourquoi

| Choix | Raison | Alternative écartée |
|---|---|---|
| **Passer par Tuya plutôt que par le protocole Amibot/Bona** | Le protocole Tuya est connu et documenté ; celui d'Amibot demanderait de la rétro-ingénierie d'une app retirée, sur un cloud qui risque de fermer. | Décompiler l'APK Bona Robot. |
| **API cloud Tuya (iot.tuya.com)** | Permet de piloter le robot hors du Wi-Fi de la maison, sans rien héberger. | Pilotage local (tinytuya, port 6668) : ne marche que sur le Wi-Fi de la maison, sauf à ajouter un serveur + VPN (Tailscale). |
| **Pas de serveur à nous** | Usage personnel uniquement : l'app appelle directement l'API Tuya. | Serveur proxy (VPS) qui garde les clés : nécessaire seulement si l'app est partagée. |
| **Clés passées à la compilation (`--dart-define-from-file=tuya.json`)** | Les clés ne sont jamais dans le code ni sur GitHub (`tuya.json` est ignoré par git). | Clés en dur dans le code. |
| **Interface `RobotService`** | Les écrans ne connaissent que cette interface : on peut changer la façon de joindre le robot (cloud, SDK, serveur, infrarouge) sans toucher à l'UI. | Appels Tuya directement dans les écrans. |
| **Mode simulé** | Sans clés, l'app tourne avec un faux robot : on peut développer l'UI sans le robot. | — |
| **Pas de SDK mobile Tuya pour l'instant** | Pas de plugin Flutter officiel (il faudrait une passerelle native Kotlin/Swift) ; gratuit seulement en version d'essai (~20 utilisateurs), puis payant (~5 000 $/an la 1ʳᵉ année, à vérifier sur tuya.com). | Connexion par compte Smart Life via le SDK. |

### Limite de sécurité connue

Les clés Tuya sont incluses dans l'APK compilé. C'est acceptable **tant que l'APK reste sur ton téléphone**. Ne jamais partager l'APK : n'importe qui pourrait en extraire les clés et piloter tous les appareils du projet Tuya.

Pour partager l'app plus tard, trois options :
1. **Chaque utilisateur saisit ses propres clés** dans un écran Réglages (stockage `flutter_secure_storage`). Gratuit, mais chacun doit créer un compte développeur Tuya.
2. **Notre projet Tuya + un serveur** : les amis lient leur compte Smart Life par QR code ; le serveur garde les clés et ne laisse chacun piloter que son robot.
3. **SDK mobile Tuya** : connexion avec le compte Smart Life. C'est le plus simple pour l'utilisateur, mais payant au-delà de la version d'essai.

Contourner la licence Tuya (réutiliser les clés de l'app Smart Life, modifier son APK) est exclu.

## État actuel

- ✅ Projet Flutter (Android + iOS), dans `C:\src\amibot_home` sur le PC.
- ✅ Écran de contrôle : démarrer, pause, retour à la base, puissance d'aspiration, état, batterie.
- ✅ Client cloud Tuya avec signature HMAC-SHA256, jeton mis en cache et renouvelé automatiquement.
- ✅ Tests : signature (vérifiée contre un calcul Python), client Tuya simulé, écran.
- ❌ Jamais testé sur le vrai robot.
- ❌ Codes de commande non vérifiés (ce sont les codes standard Tuya des robots aspirateurs).
- ❌ Jamais compilé en APK (Flutter a signalé une possible incompatibilité Java/Gradle).

## Marche à suivre

1. **Vérifier que le robot est Tuya** : réinitialiser le Wi-Fi du robot (appui long, voir le manuel), puis « Ajouter un appareil » dans l'app **Smart Life**. S'il n'est pas détecté → Plan B.
2. **Lier le robot au compte développeur** sur [iot.tuya.com](https://iot.tuya.com) :
   - Cloud → Development → Create Cloud Project (Smart Home, data center **Central Europe**) ;
   - vérifier que l'API **IoT Core** est activée ;
   - Devices → Link App Account → scanner le QR code depuis Smart Life (Moi → icône de scan) ;
   - noter l'**Access ID**, l'**Access Secret** (onglet Overview) et l'**ID du robot** (onglet Devices).
3. **Remplir les clés** : copier `tuya.example.json` en `tuya.json` et le remplir.
4. **Vérifier les codes de commande** : console Tuya → le robot → *Device Debugging*. Comparer avec les constantes en tête de `lib/robot/tuya_cloud_robot_service.dart` (`power_go`, `pause`, `switch_charge`, `suction`, `electricity_left`, `status`) et les valeurs de puissance (`gentle`, `normal`, `strong` dans `lib/robot/robot_service.dart`).
5. **Lancer sur le téléphone** et tester chaque bouton.
6. **Penser à prolonger** l'essai gratuit IoT Core dans la console Tuya quand il arrive à échéance, sinon l'app cesse de répondre.

### Plan B si le robot n'est pas Tuya

- Vérifier si le robot écoute en local : `nmap -p- <ip-du-robot>`.
- Sinon, un émetteur infrarouge Wi-Fi (Broadlink) qui apprend les touches de la télécommande, avec un nouveau `RobotService` qui l'appelle.

## Commandes

Flutter est installé côté Windows dans `C:\src\flutter` (pas dans le PATH). Depuis `C:\src\amibot_home` :

```bash
C:\src\flutter\bin\flutter.bat run
```
Mode simulé, sans clés.

```bash
C:\src\flutter\bin\flutter.bat run --dart-define-from-file=tuya.json
```
Avec le vrai robot.

```bash
C:\src\flutter\bin\flutter.bat analyze && C:\src\flutter\bin\flutter.bat test
```
Analyse et tests.

Depuis WSL, git n'a pas les identifiants GitHub : pousser avec le git de Windows (`git push` dans un terminal Windows).

## Organisation du code

```
lib/
  main.dart                              choisit le service (simulé si pas de clés, sinon cloud Tuya)
  control_screen.dart                    l'écran de contrôle
  robot/robot_service.dart               l'interface RobotService + RobotStatus + Suction
  robot/simulated_robot_service.dart     faux robot en mémoire
  robot/tuya_cloud_robot_service.dart    client API cloud Tuya (signature, jeton, commandes)
test/                                    tests du client Tuya et de l'écran
tuya.example.json                        modèle du fichier de clés (tuya.json, ignoré par git)
```

## Idées pour la suite

- Écran Réglages pour saisir les clés dans l'app (prépare le partage, option 1).
- Programmation des nettoyages, carte, historique : dépend des codes exposés par le robot.
- Passer au SDK Tuya si l'app doit être publiée : il suffit d'ajouter une implémentation de `RobotService`.
