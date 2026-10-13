#!/bin/sh
SOLR_HOME_TEMPLATE="/opt/solr/server/solr"
DEFAULT_SOLR_DATA_HOME="/solr_data_home"

init_app() {
	echo "Starting Solr initialisation"
	
	if [ -n "$SOLR_DATA_EXPORT_TARGET" ]; then
		export_solr_data
	fi
		
	init_solr_home
	init_solr_data
	
	echo "Solr initialisation completed"
}

init_solr_home() {
	if [ -z "$SOLR_HOME" ]; then
		export SOLR_HOME=$DEFAULT_SOLR_DATA_HOME
	fi
	
	[ ! -e "${SOLR_HOME}/solr.xml" ] && \
		echo "Solr home directory $SOLR_HOME does not exist or is empty"
	
	import_solr_home

	if [ ! -e "${SOLR_HOME}/solr.xml" ]; then
		echo "No solr home content was imported"
		init_solr_home_from_template
	fi
}

init_solr_data() {
	if [ -z "$SOLR_DATA_HOME" ]; then
		export SOLR_DATA_HOME=$DEFAULT_SOLR_DATA_HOME
	fi
	
	if (dir_has_content "$SOLR_DATA_HOME"); then
		echo "Found existing Solr data home at ${SOLR_DATA_HOME}, not touching it"
	else
		echo "Solr home directory $SOLR_HOME does not exist or is empty"
		import_solr_data
	fi
	
	chown -R "${SOLR_USER}:${SOLR_GROUP}" "$SOLR_DATA_HOME"
}

import_solr_home() {
	if (dir_has_content "/docker-entrypoint-initsolr.d/solr_home"); then
		echo "Found a Solr home to import"
		purge_solr_home
		cp -r "/docker-entrypoint-initsolr.d/solr_home"/* "$SOLR_HOME"
		chown -R "${SOLR_USER}:${SOLR_GROUP}" "$SOLR_HOME"
		echo "Initialised Solr home in ${SOLR_HOME}"
	fi
}

import_solr_data() {
	if (dir_has_content "/docker-entrypoint-initsolr.d/solr_data"); then
		echo "Found Solr data to import"
		purge_solr_data
		cp -r "/docker-entrypoint-initsolr.d/solr_data"/* "$SOLR_DATA_HOME"
		chown -R "${SOLR_USER}:${SOLR_GROUP}" "$SOLR_DATA_HOME"
		echo "Initialised Solr data in ${SOLR_DATA_HOME}"
	fi
}

export_solr_data() {
	if [ -d "$SOLR_DATA_EXPORT_TARGET" ]; then
		echo "Solr data export: copying existing Solr data from ${SOLR_DATA_HOME} to ${SOLR_DATA_EXPORT_TARGET}"
		cp -r "${SOLR_DATA_HOME}"/* "${SOLR_DATA_EXPORT_TARGET}"
		echo "Solr data export: done"
		exit 0
	else
		echo "Solr data export target locations does not exist or is not a directory: ${SOLR_DATA_EXPORT_TARGET}"
		exit 1
	fi
}

init_solr_home_from_template() {
	if [ "$SOLR_HOME" != "$SOLR_HOME_TEMPLATE" ]; then
		echo "Initialising Solr home with default Solr home content"
		purge_solr_home
		cp -r "${SOLR_HOME_TEMPLATE}"/* "$SOLR_HOME"
		chown -R "${SOLR_USER}:${SOLR_GROUP}" "$SOLR_HOME"
		echo "Initialised Solr home in ${SOLR_HOME}"
	fi
}

purge_solr_home() {
	if (dir_has_content "$SOLR_HOME"); then
		SOLR_HOME_BAK="${SOLR_HOME}.$(date +'%s')"
		if mkdir -p "${SOLR_HOME_BAK}"; then
			echo "Moving any original Solr home content from ${SOLR_HOME} to ${SOLR_HOME_BAK}"
			mv -f "${SOLR_HOME}"/* "${SOLR_HOME_BAK}"
		else
			echo "Could not make backup directory. Removing any original Solr home content at ${SOLR_HOME}"
			rm -rvf "${SOLR_HOME:?}"/*
		fi
	else
		mkdir -p "$SOLR_HOME"
	fi
}

purge_solr_data() {
	if (dir_has_content "$SOLR_DATA_HOME"); then
		echo "Removing any original Solr data content at ${SOLR_DATA_HOME}"
		rm -rvf "${SOLR_DATA_HOME:?}"/*
	else
		mkdir -p "${SOLR_DATA_HOME}"
	fi
}

dir_has_content() {
	[ -e "$1" ] && \
		find "$1" -not -path "$1" | grep -E ".*" > /dev/null
}

init_app
