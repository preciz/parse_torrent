# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 2016-02-28
### Added
- `parse!/1` function (might raise).
- This change log.

### Changed
- `parse` function returns a tuple or :error. BREAKING change!
- Info hash parsing is handled by Bencode from now.

### Improved
- Refactored the parsing functions.
