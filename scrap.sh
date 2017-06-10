#!/bin/bash

mkdir -p data documents

ROOT_URL="http://www.conseil-constitutionnel.fr"
DECISFILE="data/decisions.csv"
CONTRFILE="data/contributions.csv"
CONTRIBS=true

if [ ! -z "$1" ]; then
  DECISFILE="data/decisions-1958-2016.csv"
  CONTRIBS=false
fi

function datize {
  dat=$(echo $1                 |
    sed "s/juin/jun/i"          |
    sed -r "s/ (...)\S* /-\1-/" |
    sed "s/f[eé]v/feb/i"        |
    sed "s/avr/apr/i"           |
    sed "s/mai/may/i"           |
    sed "s/jui/jul/i"           |
    sed "s/ao[uû]/aug/i"        |
    sed "s/déc/dec/i"
  )
  echo $(date -d "$dat" +'%Y-%m-%d')
}

function safecurl {
  url=$1
  retries=$2
  if [ -z "$retries" ]; then
    retries=10
  fi
  curl -sL --connect-timeout 5 "$url" > /tmp/safecurl-portes-etroites.tmp
  if grep '<html' /tmp/safecurl-portes-etroites.tmp; then
    cat /tmp/safecurl-portes-etroites.tmp
  elif [ "$retries" -gt 0 ]; then
    sleep 3
    safecurl "$url" $(( $retries - 1 ))
  else
    echo "Impossible to download $url, stopping now"
    exit 1
  fi
}

HEADERS="date,numero,type,titre,décision,url"
echo "$HEADERS" > $DECISFILE
if $CONTRIBS; then
  echo "$HEADERS,auteurs_contribution,source" > $CONTRFILE
fi

YEARS_URL="$ROOT_URL/conseil-constitutionnel/francais/les-decisions/acces-par-date/decisions-depuis-1959/les-decisions-par-date.4614.html"
safecurl "$YEARS_URL"                                           |
  grep "acces-par-date/decisions-depuis-1959.*'>[0-9]\{4\}</a>" |
  while read line; do
    yurl=$(echo $line |
      sed -r "s|^.* href='([^']+)'.*$|\1|"
    )
    year=$(echo $line |
      sed -r "s|^.*>([0-9]{4})</a>.*$|\1|"
    )
    if $CONTRIBS && [ "$year" -lt 2017 ]; then
      break
    elif ! $CONTRIBS; then
      if [ "$year" -ge 2017 ]; then
        continue
      fi
      echo $year
    fi
    safecurl "$ROOT_URL$yurl"                                                       |
      tr "\n" " "                                                                   |
      sed -r "s|(</?li)|\n\1|g"                                                     |
      grep "^<li value="                                                            |
      sed -r "s|\s+| |g"                                                            |
      sed -r "s|([0-9]{2,4}-[0-9/]+) ([A-Z0-9]+) ([A-Z]+)|\1_\2 \3|g"               |
      sed -r "s|([0-9]{2,4}-[0-9/]+) à ([0-9]{2,4}-)?([0-9/]+)|\1-\3|g"             |
      sed -r "s|([0-9]{2,4}-[0-9/]+) ([A-Z]+) et ([0-9]{2,4}-[0-9/]+) \2|\1+\3 \2|g"|
      while read decision; do
        durl=$(echo $decision |
          sed -r "s|^.* href=\s*'([^']+)'\s*>.*$|\1|"
        )
        ddat=$(echo $decision |
          sed -r "s|^.*'>(.+? [0-9]{4}) - Décision n°.*$|\1|"
        )
        ddat=$(datize "$ddat")
        dnum=$(echo $decision                       |
          sed -r "s|^.*Décision n°\s*(\S+) .*$|\1|"
        )
        did=$(echo $dnum |
          sed "s|/|_|g"
        )
        dtyp=$(echo $decision |
          sed -r "s|^.*n°\s*\S+\s+(et autres\s+)?([A-Z]+[0-9]*)\s*</a>.*$|\2|"
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
        if ! $CONTRIBS; then
          continue
        fi
        contribs_url=$(safecurl "$ROOT_URL$durl"                    |
          tr "\n" " "                                               |
          sed -r "s|(</?a)|\n\1|g"                                  |
          grep "Liste des contributions\|contributions extérieures" |
          head -1                                                   |
          sed -r "s|^.* href=\s*'([^']+)'\s*>.*$|\1|"
        )
        if [ ! -z "$contribs_url" ]; then
          pdf_url=$(safecurl "$ROOT_URL$contribs_url" |
            grep ";URL="                              |
            sed -r "s|^.*;URL=(.+?)['\"].*$|\1|")
          if ! test -s "documents/$did.pdf"; then
            curl -sL "$ROOT_URL$pdf_url" > "documents/$did.pdf"
            pdftotext "documents/$did.pdf"
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

if $CONTRIBS && test -s data/decisions-1958-2016.csv; then
  cat data/decisions-1958-2016.csv |
    grep -v "^date," >> $DECISFILE
fi
