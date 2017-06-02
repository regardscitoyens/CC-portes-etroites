# « Portes étroites » au Conseil Constitutionnel

Collecte des contributions extérieures adressées au Conseil Constitutionnel sur ses dossiers issues des [listes déclarées publiquement depuis 2017](http://www.conseil-constitutionnel.fr/conseil-constitutionnel/francais/actualites/2017/communique-sur-les-contributions-exterieures.148638.html).

Vous pouvez télécharger les données directement sur ces liens (fichiers tableur CSV UTF-8):
- [Métadonnées de toutes les décisions du CC](https://github.com/regardscitoyens/CC-portes-etroites/raw/master/data/decisions.csv)
- [Liste de toutes les contributions déclarées avec métadonnées des décisions associées](https://github.com/regardscitoyens/CC-portes-etroites/raw/master/data/contributions.csv)

Les données sont redistribuées en OpenData sous ([licence ODBL](http://www.vvlibri.org/fr/licence/odbl/10/fr/legalcode)).

*Note :* Une contribution pouvant avoir plusieurs auteurs, ceux-ci sont séparés par le caractère `|` lorsque c'est le cas.

## Source

- [Décisions du Conseil Constitutionnel](http://www.conseil-constitutionnel.fr/conseil-constitutionnel/francais/les-decisions/acces-par-date/decisions-depuis-1959/les-decisions-par-date.4614.html)

## Développement

- Dépend de `pdftotext` présent sur la plupart des distributions Linux.

- Générer les métadonnées historiques des décisions entre 1958 et 2016 :

```bash
./scrap.sh 1
```

- Générer les données des décisions et des contributions depuis 2017 :

```bash
./scrap.sh
```

- Mettre à jour automatiquement les données dans le repo git :

```bash
./update.sh
```

Ou dans un cronjob :

```crontab
m  h  dom mon dow   command
05 1   *   *   *    $PATH_TO_THIS_REPO/update.sh 2>&1
```
