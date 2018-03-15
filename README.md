# webconsole-instances

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0) [![Build Status](https://secure.travis-ci.org/joyent/webconsole-instances.svg)](http://travis-ci.org/joyent/webconsole-instances)

Web console for instance management.

## Table of Contents

* [Setup](#setup)
* [Install](#install)
* [Running Without Docker](#running-without-docker)
* [Notes](#notes)

## Setup

Run `./setup.sh` to generate the local `.env` file for use with Docker.

## Install

The service can be installed and started on Triton using:

`triton-compose up -d`

or locally with

`docker-compose -f local-compose.yml up -d`

## Running Without Docker

The hapi server can be run outside of Docker by creating an environment variable configuration file and preloading it.

`node -r ./.env.js index.js `

## Notes

This service will attempt to provision instances in Triton. Developers may need to have the provisioning limits increased on their account.
