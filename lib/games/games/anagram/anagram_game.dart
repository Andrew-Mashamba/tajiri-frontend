// lib/games/games/anagram/anagram_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

// 3000+ common English words (3-7 letters)
const List<String> _kWordList = [
  // 3-letter words
  'ace', 'act', 'add', 'age', 'ago', 'aid', 'aim', 'air', 'all', 'and',
  'ant', 'any', 'ape', 'arc', 'are', 'ark', 'arm', 'art', 'ash', 'ask',
  'ate', 'awe', 'axe', 'bad', 'bag', 'ban', 'bar', 'bat', 'bay', 'bed',
  'bee', 'bet', 'bid', 'big', 'bin', 'bit', 'bow', 'box', 'boy', 'bud',
  'bug', 'bun', 'bus', 'but', 'buy', 'cab', 'can', 'cap', 'car', 'cat',
  'cow', 'cry', 'cub', 'cup', 'cur', 'cut', 'dab', 'dad', 'dam', 'day',
  'den', 'dew', 'did', 'die', 'dig', 'dim', 'dip', 'dog', 'dot', 'dry',
  'dub', 'dud', 'due', 'dug', 'dun', 'duo', 'dye', 'ear', 'eat', 'eel',
  'egg', 'ego', 'elk', 'elm', 'emu', 'end', 'era', 'eve', 'ewe', 'eye',
  'fan', 'far', 'fat', 'fax', 'fed', 'fee', 'few', 'fig', 'fin', 'fir',
  'fit', 'fix', 'flu', 'fly', 'foe', 'fog', 'for', 'fox', 'fry', 'fun',
  'fur', 'gag', 'gap', 'gas', 'gel', 'gem', 'get', 'gin', 'gnu', 'god',
  'got', 'gum', 'gun', 'gut', 'guy', 'gym', 'had', 'ham', 'has', 'hat',
  'hay', 'hen', 'her', 'hew', 'hid', 'him', 'hip', 'his', 'hit', 'hog',
  'hop', 'hot', 'how', 'hub', 'hue', 'hug', 'hum', 'hut', 'ice', 'icy',
  'ill', 'imp', 'ink', 'inn', 'ion', 'ire', 'irk', 'ivy', 'jab', 'jag',
  'jam', 'jar', 'jaw', 'jay', 'jet', 'jig', 'job', 'jog', 'jot', 'joy',
  'jug', 'jut', 'keg', 'ken', 'key', 'kid', 'kin', 'kit', 'lab', 'lad',
  'lag', 'lap', 'law', 'lay', 'lea', 'led', 'leg', 'let', 'lid', 'lie',
  'lip', 'lit', 'log', 'lot', 'low', 'lug', 'mad', 'man', 'map', 'mar',
  'mat', 'maw', 'may', 'men', 'met', 'mid', 'mix', 'mob', 'mod', 'mom',
  'mop', 'mow', 'mud', 'mug', 'nab', 'nag', 'nap', 'net', 'new', 'nil',
  'nip', 'nit', 'nod', 'nor', 'not', 'now', 'nun', 'nut', 'oak', 'oar',
  'oat', 'odd', 'ode', 'off', 'oft', 'oil', 'old', 'one', 'opt', 'orb',
  'ore', 'our', 'out', 'owe', 'owl', 'own', 'pad', 'pal', 'pan', 'pap',
  'par', 'pat', 'paw', 'pay', 'pea', 'peg', 'pen', 'pep', 'per', 'pet',
  'pew', 'pie', 'pig', 'pin', 'pit', 'ply', 'pod', 'pop', 'pot', 'pow',
  'pro', 'pry', 'pub', 'pug', 'pun', 'pup', 'pus', 'put', 'rag', 'ram',
  'ran', 'rap', 'rat', 'raw', 'ray', 'red', 'ref', 'rev', 'rib', 'rid',
  'rig', 'rim', 'rip', 'rob', 'rod', 'roe', 'rot', 'row', 'rub', 'rug',
  'rum', 'run', 'rut', 'rye', 'sac', 'sad', 'sag', 'sap', 'sat', 'saw',
  'say', 'sea', 'set', 'sew', 'she', 'shy', 'sin', 'sip', 'sir', 'sis',
  'sit', 'six', 'ski', 'sky', 'sly', 'sob', 'sod', 'son', 'sop', 'sot',
  'sow', 'soy', 'spa', 'spy', 'sty', 'sub', 'sue', 'sum', 'sun', 'sup',
  'tab', 'tad', 'tag', 'tan', 'tap', 'tar', 'tat', 'tax', 'tea', 'ten',
  'the', 'thy', 'tic', 'tie', 'tin', 'tip', 'toe', 'ton', 'too', 'top',
  'tot', 'tow', 'toy', 'try', 'tub', 'tug', 'tun', 'two', 'urn', 'use',
  'van', 'vat', 'vet', 'via', 'vie', 'vim', 'vow', 'wad', 'wag', 'war',
  'was', 'wax', 'way', 'web', 'wed', 'wet', 'who', 'why', 'wig', 'win',
  'wit', 'woe', 'wok', 'won', 'woo', 'wow', 'yak', 'yam', 'yap', 'yaw',
  'yea', 'yes', 'yet', 'yew', 'yin', 'you', 'zap', 'zed', 'zen', 'zip',
  'zoo',
  // 4-letter words
  'able', 'ache', 'acid', 'acre', 'aged', 'aide', 'ally', 'also', 'amid',
  'arch', 'area', 'army', 'arts', 'atom', 'auto', 'avid', 'away', 'axle',
  'back', 'bade', 'bail', 'bait', 'bake', 'bald', 'bale', 'ball', 'band',
  'bane', 'bang', 'bank', 'bare', 'bark', 'barn', 'base', 'bash', 'bath',
  'bead', 'beak', 'beam', 'bean', 'bear', 'beat', 'been', 'beer', 'bell',
  'belt', 'bend', 'bent', 'best', 'bias', 'bike', 'bile', 'bill', 'bind',
  'bird', 'bite', 'blew', 'blob', 'blog', 'blow', 'blue', 'blur', 'boar',
  'boat', 'body', 'boil', 'bold', 'bolt', 'bomb', 'bond', 'bone', 'book',
  'boom', 'boot', 'bore', 'born', 'boss', 'both', 'bout', 'bowl', 'bred',
  'brew', 'brim', 'brisk','buck', 'bulb', 'bulk', 'bull', 'bump', 'burn',
  'burp', 'bury', 'bush', 'busy', 'buzz', 'cafe', 'cage', 'cake', 'calf',
  'call', 'calm', 'came', 'camp', 'cane', 'cape', 'card', 'care', 'cart',
  'case', 'cash', 'cast', 'cave', 'cell', 'chat', 'chef', 'chin', 'chip',
  'chop', 'cite', 'city', 'clad', 'clam', 'clan', 'clap', 'claw', 'clay',
  'clip', 'clod', 'clog', 'clot', 'club', 'clue', 'coal', 'coat', 'code',
  'coil', 'coin', 'cold', 'cole', 'colt', 'comb', 'come', 'cone', 'cook',
  'cool', 'cope', 'copy', 'cord', 'core', 'cork', 'corn', 'cost', 'cosy',
  'coup', 'cove', 'crab', 'cram', 'crew', 'crop', 'crow', 'cube', 'cuff',
  'cult', 'curb', 'cure', 'curl', 'cute', 'dale', 'dame', 'damp', 'dare',
  'dark', 'darn', 'dart', 'dash', 'data', 'date', 'dawn', 'dead', 'deaf',
  'deal', 'dean', 'dear', 'debt', 'deck', 'deed', 'deem', 'deep', 'deer',
  'deny', 'desk', 'dial', 'dice', 'dine', 'dire', 'dirt', 'disc', 'dish',
  'dock', 'does', 'dome', 'done', 'doom', 'door', 'dose', 'dove', 'down',
  'drag', 'draw', 'drip', 'drop', 'drum', 'dual', 'duck', 'duel', 'duet',
  'duke', 'dull', 'dumb', 'dump', 'dune', 'dunk', 'dusk', 'dust', 'duty',
  'each', 'earl', 'earn', 'ease', 'east', 'easy', 'edge', 'edit', 'else',
  'emit', 'envy', 'epic', 'even', 'ever', 'evil', 'exam', 'exit', 'eyed',
  'face', 'fact', 'fade', 'fail', 'fair', 'fake', 'fall', 'fame', 'fang',
  'fare', 'farm', 'fast', 'fate', 'fawn', 'fear', 'feat', 'feed', 'feel',
  'feet', 'fell', 'felt', 'fend', 'fern', 'feud', 'file', 'fill', 'film',
  'find', 'fine', 'fire', 'firm', 'fish', 'fist', 'five', 'flag', 'flan',
  'flap', 'flat', 'flaw', 'flea', 'fled', 'flee', 'flew', 'flex', 'flip',
  'flit', 'flog', 'flop', 'flow', 'foam', 'foil', 'fold', 'folk', 'fond',
  'font', 'food', 'fool', 'foot', 'ford', 'fore', 'fork', 'form', 'fort',
  'foul', 'four', 'fowl', 'free', 'frog', 'from', 'fuel', 'full', 'fume',
  'fund', 'funk', 'fury', 'fuse', 'fuss', 'gain', 'gait', 'gale', 'game',
  'gang', 'gape', 'garb', 'gate', 'gave', 'gaze', 'gear', 'gene', 'germ',
  'gift', 'gild', 'gilt', 'girl', 'gist', 'give', 'glad', 'glee', 'glen',
  'glib', 'glob', 'gloom','glow', 'glue', 'glum', 'glut', 'gnat', 'gnaw',
  'goat', 'goes', 'gold', 'golf', 'gone', 'good', 'gore', 'gown', 'grab',
  'grad', 'gram', 'gray', 'grew', 'grid', 'grim', 'grin', 'grip', 'grit',
  'grow', 'grub', 'gulf', 'gull', 'gulp', 'gust', 'guts', 'hack', 'hail',
  'hair', 'hale', 'half', 'hall', 'halt', 'hand', 'hang', 'hare', 'harm',
  'harp', 'hash', 'haste','hate', 'haul', 'have', 'haze', 'hazy', 'head',
  'heal', 'heap', 'hear', 'heat', 'heed', 'heel', 'held', 'helm', 'help',
  'hemp', 'herb', 'herd', 'here', 'hero', 'hide', 'high', 'hike', 'hill',
  'hilt', 'hind', 'hint', 'hire', 'hiss', 'hive', 'hoax', 'hock', 'hold',
  'hole', 'holy', 'home', 'hone', 'hood', 'hook', 'hoop', 'hope', 'horn',
  'hose', 'host', 'hour', 'howl', 'huff', 'huge', 'hull', 'hump', 'hung',
  'hunt', 'hurl', 'hurt', 'hush', 'hymn', 'icon', 'idea', 'idle', 'idol',
  'inch', 'into', 'iron', 'isle', 'item', 'jack', 'jade', 'jail', 'jake',
  'jazz', 'jean', 'jeer', 'jerk', 'jest', 'jilt', 'jive', 'join', 'joke',
  'jolt', 'jump', 'June', 'jury', 'just', 'keen', 'keep', 'kelp', 'kept',
  'kick', 'kill', 'kind', 'king', 'kiss', 'kite', 'knee', 'knew', 'knit',
  'knob', 'knot', 'know', 'lace', 'lack', 'lacy', 'laid', 'lair', 'lake',
  'lamb', 'lame', 'lamp', 'land', 'lane', 'lard', 'lark', 'lash', 'lass',
  'last', 'late', 'lawn', 'lazy', 'lead', 'leaf', 'leak', 'lean', 'leap',
  'left', 'lend', 'lens', 'lent', 'less', 'lest', 'levy', 'liar', 'lice',
  'lick', 'lieu', 'life', 'lift', 'like', 'limb', 'lime', 'limp', 'line',
  'link', 'lint', 'lion', 'list', 'live', 'load', 'loaf', 'loam', 'loan',
  'lock', 'lode', 'loft', 'logo', 'lone', 'long', 'look', 'loom', 'loop',
  'loot', 'lord', 'lore', 'lose', 'loss', 'lost', 'loud', 'love', 'luck',
  'lull', 'lump', 'lure', 'lurk', 'lush', 'lust', 'lute', 'mace', 'made',
  'maid', 'mail', 'main', 'make', 'male', 'mall', 'malt', 'mane', 'many',
  'mare', 'mark', 'mars', 'mash', 'mask', 'mass', 'mast', 'mate', 'maze',
  'mead', 'meal', 'mean', 'meat', 'meek', 'meet', 'meld', 'melt', 'memo',
  'mend', 'menu', 'mere', 'mesh', 'mess', 'mild', 'mile', 'milk', 'mill',
  'mime', 'mind', 'mine', 'mint', 'mire', 'miss', 'mist', 'mite', 'mitt',
  'moan', 'moat', 'mock', 'mode', 'mold', 'mole', 'monk', 'mood', 'moon',
  'moor', 'mope', 'more', 'moss', 'most', 'moth', 'move', 'much', 'muck',
  'mule', 'mull', 'murk', 'muse', 'mush', 'must', 'mute', 'myth', 'nail',
  'name', 'nape', 'nave', 'navy', 'near', 'neat', 'neck', 'need', 'nest',
  'next', 'nice', 'nick', 'nine', 'node', 'none', 'nook', 'noon', 'norm',
  'nose', 'note', 'noun', 'nude', 'numb', 'oath', 'obey', 'odds', 'omen',
  'omit', 'once', 'only', 'onto', 'ooze', 'open', 'oral', 'orca', 'oven',
  'over', 'pace', 'pack', 'pact', 'page', 'paid', 'pail', 'pain', 'pair',
  'pale', 'palm', 'pane', 'pang', 'pant', 'pare', 'park', 'part', 'pass',
  'past', 'path', 'pave', 'peak', 'peal', 'pear', 'peat', 'peck', 'peel',
  'peer', 'pelt', 'pend', 'perk', 'perm', 'pest', 'pick', 'pier', 'pike',
  'pile', 'pill', 'pine', 'pink', 'pint', 'pipe', 'plan', 'play', 'plea',
  'plod', 'plot', 'plow', 'ploy', 'plug', 'plum', 'plus', 'pock', 'poem',
  'poet', 'poke', 'pole', 'poll', 'polo', 'pomp', 'pond', 'pony', 'pool',
  'poor', 'pope', 'pore', 'pork', 'port', 'pose', 'post', 'pour', 'pout',
  'pray', 'prep', 'prey', 'prod', 'prop', 'prow', 'pull', 'pulp', 'pump',
  'punk', 'pure', 'push', 'quit', 'race', 'rack', 'raft', 'rage', 'raid',
  'rail', 'rain', 'rake', 'ramp', 'rand', 'rang', 'rank', 'rant', 'rash',
  'rasp', 'rate', 'rave', 'rays', 'raze', 'read', 'real', 'ream', 'reap',
  'rear', 'reed', 'reef', 'reek', 'reel', 'rein', 'rely', 'rend', 'rent',
  'rest', 'rice', 'rich', 'ride', 'rift', 'rile', 'rill', 'rind', 'ring',
  'rink', 'riot', 'ripe', 'rise', 'risk', 'rite', 'road', 'roam', 'roar',
  'robe', 'rock', 'rode', 'role', 'roll', 'romp', 'roof', 'room', 'root',
  'rope', 'rose', 'rosy', 'rote', 'rout', 'rove', 'rude', 'ruin', 'rule',
  'rump', 'rung', 'runt', 'ruse', 'rush', 'rust', 'sack', 'safe', 'sage',
  'said', 'sail', 'sake', 'sale', 'salt', 'same', 'sand', 'sane', 'sang',
  'sank', 'sash', 'save', 'scab', 'scam', 'scan', 'scar', 'seal', 'seam',
  'sear', 'seat', 'sect', 'seed', 'seek', 'seem', 'seen', 'self', 'sell',
  'send', 'sent', 'shed', 'shim', 'shin', 'ship', 'shod', 'shoe', 'shop',
  'shot', 'show', 'shun', 'shut', 'sick', 'side', 'sift', 'sigh', 'sign',
  'silk', 'sill', 'silo', 'silt', 'sing', 'sink', 'sire', 'site', 'size',
  'skit', 'slab', 'slag', 'slam', 'slap', 'slat', 'slaw', 'slay', 'sled',
  'slew', 'slid', 'slim', 'slit', 'slob', 'slog', 'slop', 'slot', 'slow',
  'slug', 'slum', 'slur', 'smog', 'snap', 'snag', 'snip', 'snob', 'snore',
  'snow', 'snub', 'snug', 'soak', 'soap', 'soar', 'sock', 'soda', 'sofa',
  'soft', 'soil', 'sold', 'sole', 'solo', 'some', 'song', 'soon', 'soot',
  'sore', 'sort', 'soul', 'sour', 'span', 'spar', 'spat', 'spec', 'sped',
  'spin', 'spit', 'spot', 'spud', 'spur', 'stab', 'stag', 'star', 'stay',
  'stem', 'step', 'stew', 'stir', 'stop', 'stub', 'stud', 'stun', 'such',
  'suck', 'suit', 'sulk', 'sung', 'sunk', 'sure', 'surf', 'swan', 'swap',
  'sway', 'swim', 'swum', 'tabs', 'tack', 'tact', 'tail', 'take', 'tale',
  'talk', 'tall', 'tame', 'tank', 'tape', 'taps', 'tart', 'task', 'taut',
  'taxi', 'team', 'tear', 'tell', 'tend', 'tent', 'term', 'test', 'text',
  'than', 'that', 'them', 'then', 'they', 'thin', 'this', 'thou', 'thus',
  'tick', 'tide', 'tidy', 'tier', 'tile', 'till', 'tilt', 'time', 'tine',
  'tiny', 'tire', 'toad', 'toil', 'told', 'toll', 'tomb', 'tome', 'tone',
  'took', 'tool', 'toot', 'tops', 'tore', 'torn', 'tort', 'toss', 'tour',
  'town', 'trap', 'tray', 'tree', 'trek', 'trim', 'trio', 'trip', 'trod',
  'trot', 'true', 'tsar', 'tube', 'tuck', 'tuft', 'tune', 'turf', 'turn',
  'twig', 'twin', 'type', 'ugly', 'undo', 'unit', 'upon', 'urge', 'used',
  'user', 'vain', 'vale', 'vane', 'vary', 'vase', 'vast', 'veal', 'veil',
  'vein', 'vend', 'vent', 'verb', 'very', 'vest', 'veto', 'vial', 'vice',
  'view', 'vile', 'vine', 'visa', 'void', 'volt', 'vote', 'wade', 'wage',
  'wail', 'wait', 'wake', 'walk', 'wall', 'wand', 'wane', 'want', 'ward',
  'warm', 'warn', 'warp', 'wart', 'wary', 'wash', 'wasp', 'wave', 'wavy',
  'waxy', 'weak', 'wean', 'wear', 'weed', 'week', 'weep', 'weld', 'well',
  'went', 'wept', 'were', 'west', 'what', 'when', 'whim', 'whip', 'whir',
  'whom', 'wick', 'wide', 'wife', 'wild', 'will', 'wilt', 'wily', 'wimp',
  'wind', 'wine', 'wing', 'wink', 'wipe', 'wire', 'wise', 'wish', 'wisp',
  'with', 'wits', 'woke', 'wolf', 'womb', 'wood', 'wool', 'word', 'wore',
  'work', 'worm', 'worn', 'wove', 'wrap', 'wren', 'writ', 'yank', 'yard',
  'yarn', 'year', 'yell', 'yoga', 'yoke', 'your', 'zeal', 'zero', 'zest',
  'zinc', 'zone', 'zoom',
  // 5-letter words
  'abort', 'about', 'above', 'abuse', 'actor', 'acute', 'adapt', 'adept',
  'admin', 'admit', 'adopt', 'adult', 'after', 'again', 'agent', 'agile',
  'aging', 'agony', 'agree', 'ahead', 'alarm', 'album', 'alert', 'alien',
  'align', 'alike', 'alive', 'alley', 'allot', 'allow', 'aloft', 'alone',
  'along', 'alter', 'amber', 'amend', 'ample', 'amuse', 'angel', 'anger',
  'angle', 'angry', 'ankle', 'annex', 'antic', 'anvil', 'apart', 'apple',
  'apply', 'arena', 'argue', 'arise', 'armor', 'aroma', 'array', 'arrow',
  'aside', 'asset', 'atlas', 'attic', 'audio', 'audit', 'avoid', 'await',
  'awake', 'award', 'aware', 'awful', 'bacon', 'badge', 'badly', 'baker',
  'basic', 'basin', 'basis', 'batch', 'beach', 'beard', 'beast', 'begin',
  'being', 'belly', 'below', 'bench', 'berry', 'birth', 'black', 'blade',
  'blame', 'bland', 'blank', 'blast', 'blaze', 'bleak', 'bleed', 'blend',
  'bless', 'blind', 'blink', 'bliss', 'block', 'blond', 'blood', 'bloom',
  'blown', 'bluff', 'blunt', 'blurt', 'blush', 'board', 'boast', 'bonus',
  'boost', 'booth', 'bound', 'brace', 'brain', 'brake', 'brand', 'brass',
  'brave', 'bread', 'break', 'breed', 'brick', 'bride', 'brief', 'bring',
  'brink', 'brisk', 'broad', 'broke', 'brook', 'broom', 'broth', 'brown',
  'brush', 'buddy', 'budge', 'build', 'built', 'bulge', 'bunch', 'burst',
  'buyer', 'cabin', 'cable', 'camel', 'candy', 'cargo', 'carry', 'carve',
  'catch', 'cater', 'cause', 'cedar', 'chain', 'chair', 'chalk', 'champ',
  'chaos', 'charm', 'chart', 'chase', 'cheap', 'cheat', 'check', 'cheek',
  'cheer', 'chess', 'chest', 'chief', 'child', 'chill', 'china', 'chunk',
  'civic', 'civil', 'claim', 'clamp', 'clash', 'clasp', 'class', 'clean',
  'clear', 'clerk', 'click', 'cliff', 'climb', 'cling', 'cloak', 'clock',
  'clone', 'close', 'cloth', 'cloud', 'clown', 'coach', 'coast', 'color',
  'comet', 'comic', 'coral', 'could', 'count', 'couch', 'cough', 'court',
  'cover', 'crack', 'craft', 'crane', 'crash', 'crawl', 'craze', 'crazy',
  'creak', 'cream', 'crest', 'crime', 'crisp', 'cross', 'crowd', 'crown',
  'crude', 'cruel', 'crush', 'crust', 'curve', 'cycle', 'daily', 'dairy',
  'dance', 'death', 'debut', 'decay', 'decoy', 'decor', 'decoy', 'delay',
  'delta', 'demon', 'dense', 'depot', 'depth', 'derby', 'devil', 'diary',
  'dirty', 'dodge', 'donor', 'doubt', 'dough', 'draft', 'drain', 'drape',
  'drawl', 'drawn', 'dread', 'dream', 'dress', 'dried', 'drift', 'drill',
  'drink', 'drive', 'droit', 'drone', 'drool', 'drops', 'drown', 'drove',
  'drunk', 'dryer', 'dryly', 'dunce', 'dusty', 'dwarf', 'dwell', 'dying',
  'eager', 'eagle', 'early', 'earth', 'easel', 'eight', 'elder', 'elect',
  'elite', 'elope', 'elude', 'email', 'ember', 'empty', 'enact', 'endow',
  'enemy', 'enjoy', 'enter', 'entry', 'envoy', 'equal', 'equip', 'erect',
  'erode', 'error', 'essay', 'ethic', 'evade', 'event', 'every', 'evict',
  'exact', 'exalt', 'exile', 'exist', 'expat', 'extra', 'exult', 'fable',
  'facet', 'faint', 'fairy', 'faith', 'false', 'fancy', 'fatal', 'fault',
  'favor', 'feast', 'fence', 'ferry', 'fetch', 'fever', 'fiber', 'field',
  'fiend', 'fifth', 'fifty', 'fight', 'final', 'first', 'fixed', 'flame',
  'flank', 'flare', 'flash', 'flask', 'fleet', 'flesh', 'flick', 'fling',
  'flint', 'float', 'flock', 'flood', 'floor', 'flora', 'flour', 'flown',
  'fluid', 'fluke', 'flung', 'flush', 'flute', 'focal', 'focus', 'foggy',
  'force', 'forge', 'forth', 'forum', 'found', 'frame', 'frank', 'fraud',
  'freed', 'fresh', 'friar', 'front', 'frost', 'froze', 'fruit', 'fully',
  'fungi', 'funny', 'gauge', 'giant', 'given', 'ghost', 'giddy', 'glare',
  'glass', 'gleam', 'glide', 'globe', 'gloom', 'glory', 'gloss', 'glove',
  'gnome', 'going', 'grace', 'grade', 'grain', 'grand', 'grant', 'grape',
  'graph', 'grasp', 'grass', 'grate', 'grave', 'gravy', 'graze', 'great',
  'greed', 'green', 'greet', 'grief', 'grill', 'grind', 'gripe', 'groan',
  'groom', 'grope', 'gross', 'group', 'grove', 'growl', 'grown', 'guard',
  'guess', 'guest', 'guide', 'guild', 'guilt', 'guise', 'gulch', 'gully',
  'happy', 'harsh', 'haste', 'hasty', 'hatch', 'haunt', 'haven', 'heart',
  'heavy', 'hedge', 'heist', 'heron', 'hinge', 'hobby', 'hoist', 'homer',
  'honey', 'honor', 'horse', 'hotel', 'hound', 'house', 'human', 'humid',
  'humor', 'hurry', 'hyper', 'ideal', 'image', 'imply', 'inbox', 'index',
  'indie', 'inept', 'inert', 'infer', 'inner', 'input', 'inter', 'irony',
  'ivory', 'jewel', 'jiffy', 'joker', 'jolly', 'joust', 'judge', 'juice',
  'juicy', 'jumbo', 'kayak', 'knack', 'knead', 'kneel', 'knelt', 'knife',
  'knock', 'knoll', 'known', 'label', 'labor', 'laden', 'lance', 'large',
  'laser', 'latch', 'later', 'laugh', 'layer', 'leach', 'learn', 'lease',
  'least', 'leave', 'ledge', 'legal', 'lemon', 'level', 'lever', 'light',
  'limit', 'linen', 'liner', 'liver', 'llama', 'local', 'lodge', 'lofty',
  'logic', 'loose', 'lorry', 'lotus', 'lover', 'lower', 'loyal', 'lucky',
  'lunar', 'lunch', 'lunge', 'lusty', 'lying', 'magic', 'major', 'maker',
  'mango', 'manor', 'maple', 'march', 'marry', 'marsh', 'mason', 'match',
  'mayor', 'mealy', 'media', 'melon', 'mercy', 'merge', 'merit', 'merry',
  'metal', 'meter', 'might', 'mince', 'minor', 'minus', 'mirth', 'miser',
  'model', 'moist', 'money', 'month', 'moose', 'moral', 'morel', 'motor',
  'mound', 'mount', 'mourn', 'mouse', 'mouth', 'movie', 'muddy', 'mulch',
  'mural', 'music', 'naive', 'nerve', 'never', 'newly', 'nexus', 'night',
  'noble', 'noise', 'north', 'notch', 'noted', 'novel', 'nudge', 'nurse',
  'nylon', 'oasis', 'occur', 'ocean', 'olive', 'onset', 'opera', 'orbit',
  'order', 'organ', 'other', 'otter', 'ought', 'outer', 'outdo', 'outwit',
  'owner', 'oxide', 'ozone', 'paint', 'panel', 'panic', 'paper', 'party',
  'paste', 'patch', 'pause', 'peace', 'peach', 'pearl', 'pedal', 'penny',
  'perch', 'peril', 'phase', 'phone', 'photo', 'piano', 'piece', 'pigmy',
  'pilot', 'pinch', 'pitch', 'pixel', 'pizza', 'place', 'plaid', 'plain',
  'plane', 'plank', 'plant', 'plate', 'plaza', 'plead', 'pleat', 'plier',
  'pluck', 'plumb', 'plume', 'plump', 'plunge','plunk', 'point', 'poise',
  'polar', 'polyp', 'poser', 'pouch', 'pound', 'power', 'prank', 'prawn',
  'press', 'price', 'pride', 'prime', 'print', 'prior', 'prism', 'privy',
  'prize', 'probe', 'prone', 'proof', 'prose', 'proud', 'prove', 'prowl',
  'prude', 'prune', 'psalm', 'pulse', 'punch', 'pupil', 'purge', 'purse',
  'pushy', 'quail', 'qualm', 'queen', 'query', 'quest', 'queue', 'quick',
  'quiet', 'quill', 'quirk', 'quota', 'quote', 'rabbi', 'radar', 'radio',
  'raise', 'rally', 'ranch', 'range', 'rapid', 'raven', 'reach', 'react',
  'ready', 'realm', 'rebel', 'recap', 'refer', 'reign', 'relax', 'relay',
  'repay', 'reply', 'rider', 'ridge', 'rifle', 'right', 'rigid', 'ripen',
  'risen', 'risky', 'rival', 'river', 'roast', 'robin', 'robot', 'rocky',
  'rogue', 'roost', 'round', 'route', 'royal', 'rugby', 'ruler', 'rumor',
  'rural', 'sadly', 'saint', 'salad', 'sales', 'sauce', 'sauna', 'savor',
  'scale', 'scare', 'scene', 'scent', 'scope', 'score', 'scout', 'scrap',
  'sense', 'serve', 'seven', 'sever', 'shade', 'shaft', 'shake', 'shall',
  'shame', 'shape', 'share', 'shark', 'sharp', 'shave', 'shawl', 'shear',
  'sheen', 'sheep', 'sheer', 'sheet', 'shelf', 'shell', 'shift', 'shine',
  'shirt', 'shock', 'shore', 'short', 'shout', 'shove', 'shrub', 'shrug',
  'sight', 'sigma', 'since', 'siren', 'sixth', 'sixty', 'skate', 'skill',
  'skull', 'slack', 'slain', 'slang', 'slash', 'slate', 'slave', 'sleep',
  'sleet', 'slice', 'slide', 'slope', 'sloth', 'slugs', 'small', 'smart',
  'smash', 'smell', 'smile', 'smith', 'smoke', 'snack', 'snail', 'snake',
  'snare', 'sneak', 'snore', 'solar', 'solid', 'solve', 'sonic', 'sorry',
  'sound', 'south', 'space', 'spade', 'spare', 'spark', 'speak', 'spear',
  'speed', 'spell', 'spend', 'spent', 'spice', 'spicy', 'spill', 'spine',
  'spite', 'split', 'spoke', 'spoon', 'sport', 'spray', 'squad', 'stack',
  'staff', 'stage', 'stain', 'stair', 'stake', 'stale', 'stalk', 'stall',
  'stamp', 'stand', 'stank', 'stare', 'stark', 'start', 'state', 'stays',
  'steal', 'steam', 'steel', 'steep', 'steer', 'stern', 'stick', 'stiff',
  'still', 'sting', 'stink', 'stock', 'stoic', 'stoke', 'stole', 'stomp',
  'stone', 'stood', 'stool', 'stoop', 'store', 'stork', 'storm', 'story',
  'stout', 'stove', 'strap', 'straw', 'stray', 'strip', 'strum', 'strut',
  'stuck', 'study', 'stuff', 'stump', 'stung', 'stunk', 'stunt', 'style',
  'sugar', 'suite', 'sunny', 'super', 'surge', 'swamp', 'swarm', 'swear',
  'sweat', 'sweep', 'sweet', 'swell', 'swept', 'swift', 'swing', 'swirl',
  'swoop', 'sword', 'swore', 'sworn', 'swung', 'syrup', 'table', 'tacit',
  'taken', 'taste', 'tasty', 'taunt', 'teach', 'teeth', 'tempo', 'tense',
  'tenth', 'tepid', 'theme', 'there', 'thick', 'thief', 'thigh', 'thing',
  'think', 'third', 'thorn', 'those', 'three', 'threw', 'throw', 'thumb',
  'tiara', 'tidal', 'tiger', 'tight', 'timer', 'timid', 'tired', 'titan',
  'title', 'toast', 'today', 'token', 'tooth', 'topic', 'torch', 'total',
  'touch', 'tough', 'towel', 'tower', 'toxic', 'trace', 'track', 'trade',
  'trail', 'train', 'trait', 'tramp', 'trash', 'trawl', 'treat', 'trend',
  'trial', 'tribe', 'trick', 'tried', 'troop', 'trout', 'truck', 'truly',
  'trump', 'trunk', 'trust', 'truth', 'tulip', 'tumor', 'tuner', 'twice',
  'twist', 'tying', 'udder', 'ultra', 'uncle', 'under', 'undue', 'unfit',
  'union', 'unite', 'unity', 'until', 'upper', 'upset', 'urban', 'usage',
  'usher', 'usual', 'utter', 'vague', 'valid', 'valor', 'value', 'valve',
  'vapor', 'vault', 'venue', 'verge', 'verse', 'vigor', 'vinyl', 'viral',
  'virus', 'visit', 'visor', 'vista', 'vital', 'vivid', 'vocal', 'vodka',
  'vogue', 'voice', 'voter', 'vouch', 'vowel', 'vulgar','wager', 'wagon',
  'waist', 'waste', 'watch', 'water', 'weary', 'weave', 'wedge', 'weigh',
  'weird', 'wheat', 'wheel', 'where', 'which', 'while', 'whine', 'whirl',
  'white', 'whole', 'whose', 'wider', 'widow', 'width', 'wield', 'windy',
  'witch', 'woman', 'women', 'world', 'worry', 'worse', 'worst', 'worth',
  'would', 'wound', 'wrath', 'wreak', 'wreck', 'wring', 'wrist', 'write',
  'wrong', 'wrote', 'yacht', 'yield', 'young', 'youth', 'zebra',
  // 6-letter words
  'absorb', 'accent', 'accept', 'access', 'accord', 'across', 'action',
  'active', 'actual', 'advent', 'advice', 'affirm', 'afford', 'agenda',
  'almost', 'amount', 'anchor', 'annual', 'answer', 'anyway', 'appeal',
  'appear', 'arctic', 'around', 'arrest', 'arrive', 'artist', 'asking',
  'aspect', 'assert', 'assign', 'assist', 'assume', 'attach', 'attack',
  'attain', 'attend', 'August', 'bakery', 'banana', 'banner', 'barely',
  'basket', 'battle', 'beauty', 'became', 'become', 'before', 'behalf',
  'behave', 'behind', 'belong', 'beside', 'better', 'beyond', 'bisect',
  'biting', 'bitter', 'blanch', 'blanks', 'blight', 'bloody', 'bother',
  'bottom', 'bounce', 'branch', 'breach', 'breath', 'bridge', 'bright',
  'broken', 'broker', 'bronze', 'browse', 'bubble', 'bucket', 'budget',
  'buffer', 'buffet', 'bundle', 'burden', 'bureau', 'burger', 'burner',
  'button', 'called', 'camera', 'cancel', 'candle', 'canopy', 'carbon',
  'carpet', 'carrot', 'casino', 'castle', 'casual', 'caught', 'causal',
  'center', 'chance', 'change', 'charge', 'cheery', 'cherry', 'choice',
  'choose', 'chosen', 'church', 'circle', 'classy', 'clause', 'clever',
  'client', 'climax', 'closet', 'clumsy', 'cluster','coffee', 'column',
  'combat', 'comedy', 'coming', 'commit', 'common', 'comply', 'convey',
  'cookie', 'copper', 'corner', 'costly', 'cotton', 'county', 'couple',
  'course', 'cousin', 'create', 'credit', 'crisis', 'custom', 'damage',
  'danger', 'dealer', 'debate', 'debris', 'decade', 'decent', 'decide',
  'defeat', 'defend', 'define', 'degree', 'delete', 'demand', 'denial',
  'depart', 'depend', 'deploy', 'desert', 'design', 'desire', 'detail',
  'detect', 'device', 'devote', 'differ', 'digest', 'dinner', 'direct',
  'divide', 'divine', 'doctor', 'domain', 'donate', 'double', 'driver',
  'during', 'eating', 'editor', 'effect', 'effort', 'eighth', 'eleven',
  'emerge', 'empire', 'enable', 'ending', 'endure', 'energy', 'engage',
  'engine', 'enough', 'ensure', 'entire', 'entity', 'equity', 'escape',
  'estate', 'ethnic', 'evolve', 'exceed', 'except', 'excess', 'excuse',
  'expand', 'expect', 'expert', 'export', 'expose', 'extend', 'extent',
  'fabric', 'facial', 'factor', 'fairly', 'family', 'famous', 'farmer',
  'father', 'fathom', 'faucet', 'fellow', 'female', 'figure', 'filing',
  'filter', 'finale', 'finger', 'finish', 'fiscal', 'flavor', 'flight',
  'floppy', 'flower', 'flying', 'folder', 'follow', 'forbid', 'forced',
  'forest', 'forget', 'formal', 'format', 'former', 'fossil', 'foster',
  'fourth', 'freeze', 'frenzy', 'friend', 'frozen', 'fulfil', 'future',
  'gadget', 'gained', 'galaxy', 'gallon', 'garage', 'garden', 'gather',
  'geared', 'gender', 'gentle', 'gently', 'german', 'giggle', 'ginger',
  'giving', 'global', 'glossy', 'golden', 'gossip', 'govern', 'gravel',
  'grieve', 'groove', 'ground', 'growth', 'guilty', 'guitar', 'gutter',
  'handle', 'hangar', 'happen', 'harbor', 'hardly', 'hazard', 'headed',
  'health', 'heaven', 'height', 'helmet', 'hereby', 'hidden', 'holder',
  'hollow', 'honest', 'horror', 'hotdog', 'humble', 'hunger', 'hunter',
  'hybrid', 'ignore', 'impact', 'import', 'impose', 'income', 'indeed',
  'indoor', 'infant', 'inform', 'injure', 'injury', 'inmate', 'insect',
  'insert', 'inside', 'insist', 'intact', 'intend', 'intent', 'invent',
  'invest', 'invite', 'island', 'jacket', 'jargon', 'jersey', 'jigsaw',
  'jungle', 'junior', 'kicker', 'kidney', 'kitten', 'knight', 'ladder',
  'lambda', 'lament', 'landed', 'laptop', 'lately', 'latest', 'launch',
  'layout', 'league', 'lender', 'lesson', 'letter', 'lifted', 'likely',
  'linger', 'liquid', 'listen', 'litter', 'little', 'lively', 'living',
  'locate', 'logics', 'lonely', 'longer', 'looked', 'lounge', 'lovely',
  'lumber', 'luxury', 'magnet', 'maiden', 'mainly', 'making', 'manage',
  'manner', 'marble', 'margin', 'marine', 'marked', 'market', 'master',
  'matter', 'mature', 'meadow', 'medium', 'member', 'memory', 'mental',
  'mentor', 'merely', 'method', 'middle', 'midway', 'mighty', 'mingle',
  'mining', 'minute', 'mirror', 'modest', 'modify', 'moment', 'mortal',
  'mosque', 'mostly', 'mother', 'motion', 'motive', 'moving', 'muscle',
  'museum', 'mutual', 'muzzle', 'myriad', 'myself', 'namely', 'narrow',
  'nation', 'nature', 'nearby', 'nearly', 'neatly', 'needle', 'nicely',
  'nimble', 'nobody', 'nodded', 'normal', 'notice', 'notion', 'number',
  'object', 'obtain', 'occupy', 'offend', 'office', 'offset', 'online',
  'opener', 'oppose', 'option', 'orange', 'orient', 'origin', 'orphan',
  'outfit', 'outlet', 'output', 'outset', 'oxygen', 'oyster', 'packed',
  'paddle', 'palace', 'parade', 'parcel', 'parent', 'parish', 'patrol',
  'patron', 'paving', 'pencil', 'people', 'pepper', 'period', 'permit',
  'person', 'petrol', 'phrase', 'pillar', 'pillow', 'pinned', 'pirate',
  'plague', 'planet', 'plasma', 'player', 'please', 'pledge', 'pliers',
  'plunge', 'pocket', 'poetry', 'poison', 'police', 'policy', 'polish',
  'polite', 'pollen', 'poorly', 'portal', 'poster', 'potato', 'potent',
  'powder', 'praise', 'prayer', 'prefer', 'pretty', 'prince', 'prison',
  'profit', 'prompt', 'proper', 'propel', 'proven', 'public', 'puddle',
  'pummel', 'punish', 'puppet', 'pursue', 'puzzle', 'racket', 'radish',
  'random', 'ranger', 'rarity', 'rather', 'rattle', 'reader', 'really',
  'reason', 'recall', 'recent', 'record', 'reduce', 'reform', 'refuge',
  'refund', 'refuse', 'regard', 'regime', 'region', 'regret', 'reject',
  'relate', 'relief', 'reload', 'remain', 'remedy', 'remind', 'remote',
  'remove', 'render', 'rental', 'repair', 'repeat', 'report', 'rescue',
  'resign', 'resist', 'resort', 'result', 'resume', 'retail', 'retain',
  'retire', 'return', 'reveal', 'review', 'revolt', 'reward', 'rhythm',
  'ribbon', 'ritual', 'robust', 'rocket', 'roster', 'rotten', 'rubber',
  'rubble', 'ruling', 'runner', 'rustic', 'sacred', 'saddle', 'safari',
  'safety', 'salary', 'salmon', 'saloon', 'salute', 'sample', 'sanity',
  'savage', 'scared', 'scheme', 'school', 'scrimp', 'script', 'scroll',
  'search', 'season', 'second', 'secret', 'sector', 'secure', 'seldom',
  'select', 'seller', 'senior', 'serial', 'series', 'setoff', 'settle',
  'severe', 'shadow', 'shaker', 'shells', 'shield', 'shorts', 'should',
  'shower', 'shrink', 'signal', 'silent', 'silver', 'simple', 'simply',
  'single', 'sketch', 'slight', 'smooth', 'snatch', 'social', 'socket',
  'soften', 'solemn', 'source', 'speech', 'sphere', 'spider', 'spiral',
  'spirit', 'splash', 'spoken', 'sponge', 'spread', 'spring', 'sprint',
  'square', 'stable', 'stance', 'statue', 'status', 'steady', 'stolen',
  'strain', 'strand', 'stream', 'street', 'strict', 'stride', 'strike',
  'string', 'stripe', 'strive', 'stroke', 'strong', 'struck', 'submit',
  'subtle', 'sudden', 'suffer', 'summit', 'summon', 'supply', 'surely',
  'survey', 'switch', 'symbol', 'system', 'tackle', 'talent', 'target',
  'temple', 'tenant', 'tender', 'tenure', 'terror', 'thanks', 'thirty',
  'thirst', 'thorny', 'though', 'thread', 'threat', 'thrill', 'thrive',
  'throne', 'throng', 'thrown', 'thrust', 'ticket', 'tiller', 'timber',
  'tissue', 'today', 'toggle', 'tongue', 'toward', 'travel', 'treaty',
  'tremor', 'tribal', 'triple', 'trophy', 'truant', 'tumble', 'tunnel',
  'turkey', 'tycoon', 'unfair', 'unfold', 'unholy', 'unique', 'unless',
  'unlike', 'unrest', 'update', 'uphold', 'upkeep', 'uplift', 'uproar',
  'uproot', 'upshot', 'uptake', 'uptown', 'upward', 'urgent', 'vacant',
  'valley', 'vanish', 'vanity', 'varied', 'velvet', 'vendor', 'vessel',
  'victim', 'viewer', 'violet', 'virgin', 'virtue', 'vision', 'visual',
  'volume', 'voyage', 'waiter', 'wallet', 'wander', 'warmth', 'wealth',
  'weapon', 'weekly', 'wicked', 'widely', 'wield', 'window', 'winner',
  'winter', 'wisdom', 'within', 'wonder', 'worker', 'worthy', 'writer',
  'yellow', 'zenith',
  // 7-letter words
  'ability', 'absence', 'absolve', 'academy', 'achieve', 'acquire', 'adapted',
  'address', 'adjunct', 'adopted', 'advance', 'adverse', 'advisor', 'affable',
  'ageless', 'airport', 'alcohol', 'alleged', 'already', 'ambient', 'ancient',
  'antenna', 'anxiety', 'anybody', 'applied', 'arrange', 'article', 'artwork',
  'attempt', 'attract', 'audible', 'auditor', 'average', 'backing', 'balance',
  'balloon', 'banking', 'bargain', 'barrier', 'bastion', 'battery', 'bearing',
  'because', 'bedroom', 'believe', 'beneath', 'benefit', 'besides', 'billion',
  'blanket', 'blister', 'bonfire', 'bouquet', 'bowling', 'bracket', 'brewery',
  'broadly', 'brother', 'brought', 'buffalo', 'builder', 'bulkier', 'buoyant',
  'cabinet', 'caliber', 'camping', 'candler', 'capable', 'capital', 'captain',
  'capture', 'cardiac', 'careful', 'ceiling', 'central', 'century', 'certain',
  'chamber', 'channel', 'chapter', 'charity', 'charter', 'cheaper', 'checked',
  'chicken', 'chronic', 'circuit', 'citizen', 'claimed', 'classic', 'climate',
  'closely', 'cluster', 'coastal', 'coconut', 'collect', 'college', 'comfort',
  'command', 'comment', 'compact', 'company', 'compare', 'compel', 'compete',
  'complex', 'compose', 'compute', 'concept', 'concern', 'concise', 'condemn',
  'conduct', 'confirm', 'confuse', 'connect', 'consent', 'consist', 'consult',
  'contact', 'contain', 'content', 'contest', 'context', 'control', 'convert',
  'convict', 'cooking', 'cooling', 'copying', 'correct', 'costume', 'cottage',
  'council', 'counter', 'country', 'courage', 'coward', 'creator', 'cricket',
  'crucial', 'crusade', 'crystal', 'culture', 'cunning', 'curious', 'current',
  'cushion', 'custody', 'customs', 'cutting', 'cyclist', 'damaged', 'dealing',
  'debater', 'deceive', 'decided', 'decline', 'decrypt', 'deepest', 'default',
  'defence', 'deficit', 'deflect', 'deliver', 'density', 'deposit', 'derived',
  'deserve', 'desktop', 'despite', 'destiny', 'destroy', 'develop', 'devoted',
  'digital', 'diploma', 'disable', 'discard', 'discuss', 'disease', 'display',
  'dispute', 'distant', 'diverse', 'divided', 'dormant', 'doubted', 'draftee',
  'drawing', 'dressed', 'drinker', 'dropout', 'durable', 'dynamic', 'earlier',
  'earning', 'eastern', 'economy', 'edition', 'elderly', 'elegant', 'element',
  'elevate', 'empower', 'enabled', 'endless', 'enforce', 'engaged', 'enhance',
  'ensured', 'entropy', 'episode', 'essence', 'evening', 'evident', 'exactly',
  'examine', 'example', 'excited', 'exclude', 'execute', 'exhibit', 'expense',
  'expired', 'explain', 'exploit', 'explore', 'express', 'extinct', 'extract',
  'extreme', 'eyebrow', 'factory', 'failing', 'failure', 'fashion', 'feature',
  'federal', 'fertile', 'fiction', 'fighter', 'finance', 'finding', 'fitness',
  'fixture', 'flannel', 'flavour', 'flexing', 'florida', 'flutter', 'focused',
  'foolish', 'foreign', 'forever', 'forgive', 'formula', 'fortune', 'forward',
  'founder', 'freight', 'funeral', 'further', 'gallery', 'gateway', 'gazette',
  'general', 'genesis', 'genetic', 'genuine', 'gesture', 'getting', 'glacier',
  'glimpse', 'glucose', 'gradual', 'granite', 'graphic', 'gravity', 'greatly',
  'grocery', 'grounds', 'growing', 'habitat', 'halfway', 'handful', 'handler',
  'hanging', 'happily', 'harbour', 'healing', 'healthy', 'hearing', 'helpful',
  'herself', 'highest', 'highway', 'himself', 'himself', 'history', 'holding',
  'holiday', 'horizon', 'hostile', 'housing', 'however', 'illegal', 'imagery',
  'imagine', 'immense', 'implied', 'imposed', 'impress', 'improve', 'impulse',
  'include', 'indexed', 'Indiana', 'inflate', 'initial', 'innings', 'inquire',
  'inspect', 'install', 'instant', 'integer', 'interim', 'intrude', 'invalid',
  'involve', 'isolate', 'jointly', 'journal', 'journey', 'justice', 'justify',
  'keeping', 'keynote', 'kitchen', 'knowing', 'landing', 'largely', 'lasting',
  'lateral', 'leading', 'learned', 'leather', 'leisure', 'lengthy', 'lending',
  'leopard', 'liberal', 'liberty', 'library', 'license', 'lighter', 'limited',
  'linking', 'literal', 'logical', 'longest', 'loosely', 'luggage', 'machine',
  'madness', 'magnify', 'mammoth', 'manager', 'mankind', 'mapping', 'marital',
  'marking', 'martial', 'massive', 'mastery', 'matched', 'meaning', 'measure',
  'medical', 'meeting', 'melting', 'mention', 'mercury', 'message', 'methane',
  'midterm', 'migrate', 'militia', 'million', 'mineral', 'minimal', 'minimum',
  'miracle', 'missile', 'mission', 'mistake', 'mixture', 'mobbing', 'monitor',
  'monster', 'monthly', 'morning', 'moulded', 'mounted', 'moulder', 'mourner',
  'mounted', 'mundane', 'myspace', 'mystery', 'narrate', 'natural', 'nearest',
  'neglect', 'neither', 'nervous', 'network', 'neutral', 'notably', 'nothing',
  'novelty', 'nucleus', 'nurture', 'obliged', 'obscure', 'observe', 'obvious',
  'offence', 'officer', 'omitted', 'ongoing', 'opening', 'operate', 'opinion',
  'optimal', 'organic', 'origins', 'outdoor', 'outlook', 'outline', 'outside',
  'overall', 'overlap', 'oversee', 'package', 'painful', 'painter', 'palatal',
  'parking', 'partial', 'partner', 'passage', 'passing', 'passion', 'patient',
  'pattern', 'payload', 'payment', 'peasant', 'penalty', 'pending', 'pension',
  'percent', 'perfect', 'perhaps', 'pioneer', 'plastic', 'playful', 'pleased',
  'podcast', 'pointer', 'politic', 'polling', 'polymer', 'popular', 'portion',
  'possess', 'pottery', 'poverty', 'powered', 'precede', 'predict', 'premier',
  'premium', 'prepare', 'present', 'preside', 'presume', 'prevent', 'primate',
  'primary', 'printer', 'privacy', 'private', 'problem', 'proceed', 'process',
  'produce', 'product', 'profile', 'program', 'project', 'promise', 'promote',
  'protest', 'provide', 'provoke', 'publish', 'pudding', 'pulling', 'purpose',
  'qualify', 'quarter', 'quickly', 'radical', 'railing', 'rainbow', 'ranking',
  'reading', 'reality', 'realize', 'rebuild', 'receive', 'recover', 'recruit',
  'reduced', 'reflect', 'refugee', 'refusal', 'regular', 'related', 'release',
  'relaxed', 'remains', 'removal', 'renewal', 'replica', 'replace', 'request',
  'require', 'reserve', 'resolve', 'respect', 'respond', 'restore', 'retired',
  'retreat', 'returns', 'reunion', 'revenue', 'reverse', 'revised', 'revolve',
  'robbery', 'roughly', 'routine', 'royalty', 'running', 'rupture', 'sachets',
  'sadness', 'scatter', 'scenery', 'scholar', 'science', 'scratch', 'seating',
  'section', 'segment', 'seizure', 'senator', 'serious', 'servant', 'service',
  'session', 'setting', 'settled', 'seventh', 'several', 'shallow', 'shelter',
  'shifted', 'shining', 'shipped', 'shocked', 'shortly', 'shotgun', 'showing',
  'shutout', 'shuttle', 'silence', 'similar', 'skilled', 'slender', 'slicing',
  'slipped', 'smaller', 'snippet', 'society', 'soldier', 'somehow', 'speaker',
  'special', 'sponsor', 'stadium', 'stamina', 'standby', 'started', 'startup',
  'station', 'stealth', 'storage', 'strange', 'subject', 'subsidy', 'suburbs',
  'succeed', 'success', 'suggest', 'summary', 'support', 'supreme', 'surgeon',
  'surplus', 'surreal', 'survive', 'suspect', 'suspend', 'sustain', 'symptom',
  'tactics', 'teacher', 'telecom', 'terrain', 'textile', 'theatre', 'therapy',
  'thereby', 'thermal', 'thought', 'through', 'tonight', 'tourism', 'tourist',
  'towards', 'tracker', 'trading', 'traffic', 'trainer', 'transit', 'trouble',
  'trusted', 'trustee', 'tuition', 'turning', 'tussled', 'typical', 'unaware',
  'uncover', 'undergo', 'unified', 'unitary', 'unknown', 'unlawry', 'deliver',
  'unusual', 'upright', 'utility', 'vaccine', 'variety', 'vehicle', 'venture',
  'verdict', 'version', 'veteran', 'village', 'vintage', 'violate', 'virtual',
  'visible', 'visitor', 'volcano', 'voltage', 'warfare', 'warrant', 'warrior',
  'weather', 'website', 'wedding', 'weekend', 'welcome', 'welfare', 'western',
  'whistle', 'whoever', 'willing', 'winning', 'witness', 'working', 'workout',
  'worship', 'wrapper', 'writing', 'written', 'younger',
];

// Build a lookup set for validation
final Set<String> _kWordSet = _kWordList.toSet();

class AnagramGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const AnagramGame({super.key, required this.gameContext});

  @override
  State<AnagramGame> createState() => AnagramGameState();
}

class AnagramGameState extends State<AnagramGame> implements GameInterface {
  late final List<String> _letters; // 7 available letters
  final List<int> _selectedIndices = []; // indices into _letters for current word
  final List<String> _foundWords = [];
  final Map<String, int> _wordScores = {};
  int _score = 0;
  int _timeRemaining = 90;
  bool _gameOver = false;
  Timer? _timer;
  String _message = '';

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'anagram';

  @override
  void initState() {
    super.initState();
    _generateLetters();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateLetters() {
    final rng = Random(_ctx.gameSeed.hashCode);
    const vowels = 'aeiou';
    const consonants = 'bcdfghjklmnpqrstvwxyz';

    final letters = <String>[];
    // Guarantee at least 2 vowels
    for (int i = 0; i < 2; i++) {
      letters.add(vowels[rng.nextInt(vowels.length)]);
    }
    // Fill rest with random letters (biased towards consonants)
    for (int i = 2; i < 7; i++) {
      if (rng.nextDouble() < 0.35) {
        letters.add(vowels[rng.nextInt(vowels.length)]);
      } else {
        letters.add(consonants[rng.nextInt(consonants.length)]);
      }
    }
    letters.shuffle(rng);
    _letters = letters;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeRemaining--);
      if (_timeRemaining <= 0) {
        t.cancel();
        _endGame();
      }
    });
  }

  void _toggleLetter(int index) {
    if (_gameOver) return;
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      _message = '';
    });
  }

  void _submitWord() {
    if (_gameOver || _selectedIndices.isEmpty) return;

    final word = _selectedIndices.map((i) => _letters[i]).join();

    if (word.length < 3) {
      setState(() => _message = 'Too short (min 3 letters)');
      return;
    }
    if (_foundWords.contains(word)) {
      setState(() => _message = 'Already found!');
      return;
    }
    if (!_kWordSet.contains(word)) {
      setState(() => _message = 'Not a valid word');
      return;
    }
    // Check letters are available (each index used at most once - enforced by toggle)
    // Passed all checks
    int points;
    switch (word.length) {
      case 3:
        points = 3;
        break;
      case 4:
        points = 5;
        break;
      case 5:
        points = 8;
        break;
      case 6:
        points = 12;
        break;
      case 7:
        points = 20;
        break;
      default:
        points = 3;
    }

    setState(() {
      _foundWords.insert(0, word);
      _wordScores[word] = points;
      _score += points;
      _selectedIndices.clear();
      _message = '+$points!';
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
      _message = '';
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() => _gameOver = true);
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (_score > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _score,
      'player_2_score': 0,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final words = (savedState['foundWords'] as List?)?.cast<String>() ?? [];
    setState(() {
      _foundWords.addAll(words);
      _score = savedState['score'] as int? ?? 0;
      _timeRemaining = savedState['timeRemaining'] as int? ?? 90;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'foundWords': _foundWords,
      'score': _score,
      'timeRemaining': _timeRemaining,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTimerBar(),
            const SizedBox(height: 16),
            _buildLetterTiles(),
            const SizedBox(height: 8),
            _buildWordArea(),
            const SizedBox(height: 8),
            _buildButtons(),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _message.startsWith('+')
                          ? Colors.green
                          : _kSecondary,
                    )),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildFoundWords()),
            if (_gameOver) _buildGameOverButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Anagram Battle / Vita vya Herufi',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Score: $_score',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final fraction = _timeRemaining / 90.0;
    final color = _timeRemaining > 30
        ? Colors.green
        : _timeRemaining > 10
            ? Colors.orange
            : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('${_timeRemaining}s',
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLetterTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (i) {
          final isSelected = _selectedIndices.contains(i);
          return GestureDetector(
            onTap: () => _toggleLetter(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _kPrimary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _letters[i].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : _kPrimary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWordArea() {
    final word =
        _selectedIndices.map((i) => _letters[i].toUpperCase()).join();
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        word.isEmpty ? 'Tap letters to form a word' : word,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: word.isEmpty ? _kSecondary : _kPrimary,
          letterSpacing: 2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: _clearSelection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Clear'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _selectedIndices.isNotEmpty ? _submitWord : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit / Tuma'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundWords() {
    if (_foundWords.isEmpty) {
      return const Center(
        child: Text('No words found yet',
            style: TextStyle(color: _kSecondary, fontSize: 14)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _foundWords.length,
      itemBuilder: (context, i) {
        final word = _foundWords[i];
        final pts = _wordScores[word] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(word.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary)),
              const Spacer(),
              Text('+$pts',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameOverButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Done / Maliza'),
        ),
      ),
    );
  }
}
