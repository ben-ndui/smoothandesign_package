# CLAUDE.md — smoothandesign_package

> **Base de connaissance centralisée :** `/Users/wesof./.smooth-brain/`
> Lire en priorité : `stacks/flutter-bloc.md` + `cross-project/shared-package.md` + `conventions/dart.md`

---

## Package : smoothandesign_package

**Type :** Dart Package partagé
**Version :** v1.1.0
**Utilisé par :**
- `easybiz` (path: `../smoothandesign_package`)
- `useme` (git: `ben-ndui/smoothandesign_package`)

**Stack :** Flutter 3.8+ + BLoC

### API complète
Voir `/Users/wesof./.smooth-brain/cross-project/shared-package.md`

### ⚠️ Règles critiques
- Tout changement ici impacte **easybiz** ET **useme** — toujours tester les deux apps après modification.
- Versioner via git tags : `git tag v1.x.x && git push origin v1.x.x`
- `useme` tire le package via git ref → toujours pousser les tags avant de mettre à jour `pubspec.yaml` dans useme.
- Toujours utiliser `fvm flutter` (jamais `flutter` directement).

### Commandes
```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter pub publish --dry-run  # Vérifier avant publish
```
