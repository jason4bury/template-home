# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), with versions numbered
`<major>.<minor>` and a two-digit minor (v1.00, v1.01 ... v1.10).

## [Unreleased]

## [1.00] - 2026-11-13
First release.

### Added
- `starter\`: README (house section order, emoji H2s, badge row), CHANGELOG, MIT LICENSE,
  .gitignore, .gitattributes, PSScriptAnalyzerSettings.psd1, config.example.json, build.json,
  launcher.json, Build-Exe.cmd (builds from build.json), a start launcher, issue templates and
  a starter PowerShell/WPF script with the house-style About box.
- `Initialize-Template.ps1` and `New Home Tool.cmd`: make `Home\<Name>\Source` and `Builds`
  (or `Home\Private\<Name>` with `-Private`) from the starter, or fill in a repo made with
  GitHub's **Use this template** (`-InPlace`). Draws a placeholder icon from the initials.
