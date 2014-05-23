PLUGIN  = vimya
VERSION = 0.5

SOURCE  = plugin/${PLUGIN}.vim
SOURCE += doc/${PLUGIN}.txt

EXTRA   = COPYING
EXTRA  += README

all: ${PLUGIN}-${VERSION}.vba ${PLUGIN}-${VERSION}.zip

${PLUGIN}-${VERSION}.vba: ${SOURCE}
	mkvimball ${PLUGIN} ${SOURCE}
	mv ${PLUGIN}.vba ${PLUGIN}-${VERSION}.vba

${PLUGIN}-${VERSION}.zip: ${SOURCE} ${EXTRA}
	mkdir ${PLUGIN}-${VERSION}
	cp --parents ${SOURCE} ${EXTRA} ${PLUGIN}-${VERSION}
	7z a -tzip ${PLUGIN}-${VERSION}.zip ${PLUGIN}-${VERSION} -mx=9
	rm -rf ${PLUGIN}-${VERSION}

clean:
	rm ${PLUGIN}-${VERSION}.vba
	rm ${PLUGIN}-${VERSION}.tar.gz
