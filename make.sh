#!/usr/bin/env bash

# Stricter shell handling
set -euo pipefail

if ! command -v zip &>/dev/null; then
  echo "ZIP not found!"
  echo "Make sure you have the 'zip' command installed."
  exit 1
fi

# Setup functions
IDENT_LEVEL=0

function IndentFurther {
  IDENT_LEVEL=$((IDENT_LEVEL + 1))
}

function IndentBack {
  IDENT_LEVEL=$((IDENT_LEVEL - 1))
}

function Logger {
  printf "%$((IDENT_LEVEL * 2))s%s\n" "" "$1"
}

SRC="${PWD}/src"
BUILD="${PWD}/build"
DIST="${PWD}/dist"

function CleanBuild {
  rm -r "${BUILD}" || true
  rm -r "${DIST}" || true
}

function CopyDirectory {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"

  if [[ -d "${SRC_TARGET}" ]]; then
    Logger "Copying directory over ${SRC_AND_PARENT}"
    cp -r "${SRC_TARGET}" "${DEST_TARGET}"
  else
    Logger "Source directory ${SRC_AND_PARENT} does not exist or is not a directory - can't copy."
  fi
}

function CopyDirectoryContents {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT
  local DEST_DIR
  local DEST_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  DEST_DIR="$(basename -- "${DEST_TARGET}")"
  DEST_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${DEST_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"
  local DEST_AND_PARENT="${DEST_PARENT}/${DEST_DIR}"

  if [[ -d "${SRC_TARGET}" ]]; then
    Logger "Copying over contents of ${SRC_AND_PARENT} to ${DEST_AND_PARENT}"
    mkdir -p "${DEST_TARGET}"
    cp -r "${SRC_TARGET}/." "${DEST_TARGET}/"
  else
    Logger "Source directory ${SRC_AND_PARENT} does not exist or is not a directory - can't copy."
  fi
}

function MakeZIP {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT
  local DEST_DIR
  local DEST_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  DEST_DIR="$(basename -- "${DEST_TARGET}")"
  DEST_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${DEST_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"
  local DEST_AND_PARENT="${DEST_PARENT}/${DEST_DIR}"

  IndentFurther
  Logger "Moving to ${SRC_AND_PARENT}"
  cd "${SRC_TARGET}"

  IndentFurther
  Logger "Making ${DEST_AND_PARENT}"
  find . -type f | sort | zip "${DEST_TARGET}" -@ &> /dev/null
  IndentBack

  cd - &> /dev/null
  IndentBack
}

# Actual work

Logger "Cleaning up..."

CleanBuild

Logger "Starting build setup..."

mkdir -p "${BUILD}"
mkdir -p "${DIST}"

BUILD_RESULT="$(realpath "${BUILD}/qol")"

DIST_RESULT="$(realpath "${DIST}/qol.pk3")"

IndentFurther

CopyDirectory "${SRC}" "${BUILD_RESULT}"

IndentBack

Logger "Bundling for distribution..."

MakeZIP "${BUILD_RESULT}" "${DIST_RESULT}"

Logger "Finished building mod!"
