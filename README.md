# amibot_home

Télécommande Flutter pour un aspirateur Amibot Spirit H2O relié au cloud Tuya (Smart Life).

## Lancer

Sans clés, l'app tourne en mode simulé :

```bash
flutter run
```

Avec le vrai robot : copier `tuya.example.json` en `tuya.json` (ignoré par git), le remplir depuis iot.tuya.com, puis :

```bash
flutter run --dart-define-from-file=tuya.json
```

Les codes de commande (`power_go`, `switch_charge`, `suction`…) sont en tête de `lib/robot/tuya_cloud_robot_service.dart` ; vérifier les vrais dans la console Tuya, onglet Device Debugging du robot.
