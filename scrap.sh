#!/bin/bash

mkdir -p data documents

ROOT_URL="http://www.conseil-constitutionnel.fr"
DECISFILE="data/decisions.csv"
CONTRFILE="data/contributions.csv"

# TODO
# - dates ISO
# - collect all decisions
# - updater auto

HEADERS="date,numero,type,titre,décision,url"
echo "$HEADERS" > $DECISFILE
echo "$HEADERS,auteurs_contribution,source" > $CONTRFILE

YEARS_URL="$ROOT_URL/conseil-constitutionnel/francais/les-decisions/acces-par-date/decisions-depuis-1959/les-decisions-par-date.4614.html"
curl -sL "$YEARS_URL"                                           |
  grep "acces-par-date/decisions-depuis-1959.*'>[0-9]\{4\}</a>" |
  while read line; do
    yurl=$(echo $line |
      sed -r "s|^.* href='([^']+)'.*$|\1|"
    )
    year=$(echo $line |
      sed -r "s|^.*>([0-9]{4})</a>.*$|\1|"
    )
    if [ "$year" -lt 2017 ]; then
      break
    fi
    curl -sL "$ROOT_URL$yurl"   |
      tr "\n" " "               |
      sed -r "s|(</?li)|\n\1|g" |
      grep "^<li value="        |
      sed -r "s|\s+| |g"        |
      while read decision; do
        durl=$(echo $decision |
          sed -r "s|^.* href=\s*'([^']+)'\s*>.*$|\1|"
        )
        ddat=$(echo $decision |
          sed -r "s|^.*'>(.+? [0-9]{4}) - Décision n°.*$|\1|"
        )
        dnum=$(echo $decision                       |
          sed -r "s|^.*Décision n°\s*(\S+) .*$|\1|" |
          sed "s|/|_|g"
        )
        dtyp=$(echo $decision |
          sed -r "s|^.*n°\s*\S+\s+([A-Z]+)\s*</a>.*$|\1|"
        )
        dtit=$(echo $decision                       |
          sed -r "s|^.*<em>(.+?)\s*<br\s*/>.*$|\1|" |
          sed 's|"|""|g'                            |
          sed "s/^\s*//"                            |
          sed "s/\s*$//"
        )
        ddec=$(echo $decision |
          sed -r "s|^.*<small>\[(.+?)\]</small>.*$|\1|"
        )
        if [ "$ddec" = "$decision" ]; then
          ddec=""
        fi
        contrib_metas="$ddat,$dnum,$dtyp,\"$dtit\",$ddec,$ROOT_URL$durl"
        echo "$contrib_metas" >> $DECISFILE
        contribs_url=$(curl -sL "$ROOT_URL$durl"                    |
          tr "\n" " "                                               |
          sed -r "s|(</?a)|\n\1|g"                                  |
          grep "Liste des contributions\|contributions extérieures" |
          head -1                                                   |
          sed -r "s|^.* href=\s*'([^']+)'\s*>.*$|\1|"
        )
        if [ ! -z "$contribs_url" ]; then
          pdf_url=$(curl -sL "$ROOT_URL$contribs_url" |
            grep ";URL="                              |
            sed -r "s|^.*;URL=(.+?)['\"].*$|\1|")
          if ! test -s "documents/$dnum.pdf"; then
            curl -sL "$ROOT_URL$pdf_url" > "documents/$dnum.pdf"
            pdftotext "documents/$dnum.pdf"
            echo "Nouvelle décision du CC avec liste de portes étroites :"
            echo " -> $dnum $dtyp ($ddat) $dtit ($ddec)"
            echo "    $ROOT_URL$pdf_url"
          fi
          cat "documents/$dnum.txt"                 |
            tr "\n" "|"                             |
            sed -r "s/^.*Contributions[^\|]*?\|+//" |
            sed -r "s/+/\n/g"                      |
            sed -r "s/\s*\|\s*/|/g"                 |
            sed -r "s/^[\|\s]+//"                   |
            sed -r "s/[\|\s]+$//"                   |
            sed 's|"|""|g'                          |
            grep .                                  |
            while read contrib; do
              echo "$contrib_metas,\"$contrib\",$ROOT_URL$pdf_url" >> $CONTRFILE
            done
        fi
      done
  done
