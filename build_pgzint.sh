#!/bin/bash

PROG=$(basename $0)
UTILDIR=$(dirname $0)

PGVERSIONS="9.4.22 9.5.17 9.6.13 10.8 11.3"
PGCONFIG="--with-readline --with-openssl --with-pam --with-krb5"
PGZINTVER=0.1.3
PGZINTURL="https://github.com/davidbeauchamp/pgzint.git"
INITIALPATH="$PATH"
STARTDIR=$(pwd)
BUILDDIR=$(pwd)/pgzint_builds
OS=$(uname -s)

function die() {
  echo "$*"
  exit 2
}

case $OS in
  Darwin) ARCHES="x86_64"
          PGCONFIG="$PG_CONFIG --with-bonjour"
          ;;
  Linux)  ARCHES=$(uname -i)
          ;;
esac

if [ "$UTILDIR" = "." -o "$UTILDIR" = "./" ] ; then
  UTILDIR="$(pwd)"
elif ! [[ $UTILDIR =~ ^/ ]] ; then
  UTILDIR="$(pwd)/$UTILDIR"
fi
[ -d "$BUILDDIR" ] || mkdir -p "$BUILDDIR"       || die
cd "$BUILDDIR"                                   || die
rm -rf "${BUILDDIR}/pgzint"
mkdir -p "${BUILDDIR}/pgzint"                    || die

for PGVER in $PGVERSIONS ; do
  if [ ! -f postgresql-${PGVER}.tar.bz2 ] ; then
    curl https://ftp.postgresql.org/pub/source/v${PGVER}/postgresql-${PGVER}.tar.bz2 \
         -o postgresql-${PGVER}.tar.bz2         || die
  fi
done

for PGVER in $PGVERSIONS ; do
  LIPOARGS=""

  for ARCH in $ARCHES ; do
    cd "${BUILDDIR}"
    PATH="$INITIALPATH"

    if [ ! -d postgresql-${PGVER}-${ARCH} ] ; then
      tar xf postgresql-${PGVER}.tar.bz2                                || die
      mv postgresql-${PGVER} postgresql-${PGVER}-${ARCH}                || die
    fi
    cd postgresql-${PGVER}-${ARCH}                                      || die
    if [ "$OS" = Darwin ] ; then
      ./configure --prefix="${BUILDDIR}/pg-${PGVER}-${ARCH}" $PGCONFIG CFLAGS="-arch $ARCH" || die
    else
      ./configure --prefix="${BUILDDIR}/pg-${PGVER}-${ARCH}" $PGCONFIG  || die
    fi
    make -j$(nproc) install || die

    cd ${BUILDDIR}                                                      || die
    [ -d pgzint_${ARCH} ] || git clone $PGZINTURL pgzint_${ARCH}        || die
    cd ${BUILDDIR}/pgzint_${ARCH}                                       || die
    make clean
    git checkout ${PGZINTVER}                                             || die
    PATH="${BUILDDIR}/pg-${PGVER}-${ARCH}/bin:${INITIALPATH}"
    make -j$(nproc)                                                     || die
    LIPOARGS="${LIPOARGS} -arch ${ARCH} $(pwd)/pgzint.so"
  done

  case ${OS} in
    Darwin)
      lipo -create -output "${BUILDDIR}/pgzint/pgzint_${PGVER}.so" $LIPOARGS      || die
     ;;
    *)
      cp pgzint.so "${BUILDDIR}/pgzint/pgzint_${PGVER}.so" || die
      ;;
  esac
done

cd "${BUILDDIR}"                                                        || die
cp "${BUILDDIR}"/pgzint_${ARCH}/*.{sql,control} pgzint                  || die
tar czf pgzint.tgz pgzint                                               || die
