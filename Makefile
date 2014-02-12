PLUGIN  = vimya
VERSION = 0.4

SOURCE  = plugin/${PLUGIN}.vim
SOURCE += doc/${PLUGIN}.txt

EXTRA   = COPYING
EXTRA  += README

all: ${PLUGIN}-${VERSION}.vba ${PLUGIN}-${VERSION}.zip

${PLUGIN}-${VERSION}.vba: ${SOURCE}
	mkvimball ${PLUGIN} ${SOURCE}
	mv ${PLUGIN}.vba ${PLUGIN}-${VERSION}.vba

${PLUGIN}-${VERSION}.zip: ${SOURCE} ${EXTRA}
	7z a -tzip ${PLUGIN}-${VERSION}.zip ../${PLUGIN} -mx=9 \
		-xr'!*.vba' -xr'!*.zip' -xr'!Makefile' -xr'!.*'

clean:
	rm ${PLUGIN}-${VERSION}.vba
	rm ${PLUGIN}-${VERSION}.tar.gz
