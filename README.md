![SEL Logo](https://i.imgur.com/cTu1FE5.png)

__Automatically generated libraries and documentation for Minecraft, Minecraft: Pocket Edition and SEL__

[![Join chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/sel-project/Lobby)

Automatically generated documentation is available at the [project's website](https://sel-utils.github.io/).

### Data provided

The following data is provided through [XML files](https://github.com/sel-project/sel-utils/tree/master/xml) and it's used to generate code using the generators in the [gen](https://github.com/sel-project/sel-utils/tree/master/gen) directory and the templates in the [templates](https://github.com/sel-project/sel-utils/tree/master/templates) directory.

| | Description | Available
|:---:|---|:---:
| Protocol | Packets with encoding and decoding | ✓
| Metadata | Types and encoding | ✓
| Blocks | Ids and behaviours | ✓
| Items | Ids, metas and stack size | ✓
| Entities | Ids and sizes | ✓
| Effects | Ids and particles' colours | ✓
| Enchantments | Ids and highest level | ✓
| Biomes | Ids and temperature | ✓
| Windows | Ids | 
| Recipes | | 
| Creative Inventory | Minecraft: Pocket Edition's items in the creative inventory | ✓

The provided data can be used with the language's package manager (see the badges) or as git submodule.

You can choose a specific protocol using the combination `software` + `protocol` or the latest release of the protocol using just `software`.

```
git init .
git submodule add -b minecraft316 git://github.com/sel-utils/java minecraft316/sul
```
And add `minecraft316` to your source paths

```
git init .
git submodule add -b pocket git://github.com/sel-utils/d pocket/sul
```
And compile using -Ipocket

Utils must always be added to submodules
```
git submodule add -b utils git://github.com/sel-utils/php utils/sul
```

### Projects using sel-utils

| | Type | Language | Used Data
|---:|---|---|---
| [sel-server](https://github.com/sel-project/sel-server) | server (MC and MCPE) | D | protocol, metadata, blocks, items, effects, enchantments, biomes, creative inventory
| [sel-client](https://github.com/sel-project/sel-client) | client (MC and MCPE) | D | protocol

### Generated code

**Jump to**: [C#](#csharp), [D](#d), [Java](#java), [PHP](#php)

326&#8239;503 lines of code in 1&#8239;680 files

### [C#](https://github.com/sel-utils/csharp)

[![Build Status](https://ci.appveyor.com/api/projects/status/r64c62387r8j9424?svg=true)](https://ci.appveyor.com/project/Kripth/csharp) 

- [x] Protocol
- [ ] Metadata
- [ ] Blocks
- [ ] Items
- [ ] Entities
- [ ] Effects
- [ ] Enchantments
- [ ] Biomes
- [ ] Windows
- [ ] Recipes


### [D](https://github.com/sel-utils/d)

[![Build Status](https://travis-ci.org/sel-utils/d.svg?branch=master)](https://travis-ci.org/sel-utils/d) [![DUB Package](https://img.shields.io/dub/v/sel-utils.svg)](https://code.dlang.org/packages/sel-utils) [![DUB Downloads](https://img.shields.io/dub/dt/sel-utils.svg)](https://code.dlang.org/packages/sel-utils) 

- [ ] Protocol
- [x] Metadata
- [x] Blocks
- [x] Items
- [x] Entities
- [x] Effects
- [x] Enchantments
- [x] Biomes
- [ ] Windows
- [ ] Recipes


### [Java](https://github.com/sel-utils/java)

[![Build Status](https://travis-ci.org/sel-utils/java.svg?branch=master)](https://travis-ci.org/sel-utils/java) [![Release](http://github-release-version.herokuapp.com/github/sel-utils/java/release.svg)](https://github.com/sel-utils/java/releases/latest) 

- [ ] Protocol
- [ ] Metadata
- [x] Blocks
- [x] Items
- [x] Entities
- [ ] Effects
- [x] Enchantments
- [x] Biomes
- [ ] Windows
- [ ] Recipes


### [PHP](https://github.com/sel-utils/php)

[![Build Status](https://travis-ci.org/sel-utils/php.svg?branch=master)](https://travis-ci.org/sel-utils/php) [![Composer Package](https://poser.pugx.org/sel-project/sel-utils/v/stable)](https://packagist.org/packages/sel-project/sel-utils) [![Composer Downloads](https://poser.pugx.org/sel-project/sel-utils/downloads)](https://packagist.org/packages/sel-project/sel-utils) 

- [x] Protocol
- [ ] Metadata
- [ ] Blocks
- [x] Items
- [ ] Entities
- [ ] Effects
- [ ] Enchantments
- [ ] Biomes
- [ ] Windows
- [ ] Recipes
