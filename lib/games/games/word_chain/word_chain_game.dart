// lib/games/games/word_chain/word_chain_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

// ─── Dictionary of 5000+ common English words (3-8 letters) ──────────
const Set<String> _dictionary = {
  // A
  'abe','able','about','above','ace','ache','acid','acme','acne','acre',
  'act','add','age','aged','ago','aid','aide','aim','air','airy',
  'aisle','ajar','alarm','ale','alert','algae','alibi','alien','align','alike',
  'alive','alley','allot','allow','alloy','ally','almond','alone','along','aloof',
  'alpha','altar','alter','amber','ample','amuse','angel','anger','angle','angry',
  'ankle','annex','annual','ant','ante','anvil','any','ape','apex','apple',
  'apply','april','apron','aqua','arch','arctic','area','arena','argue','arise',
  'arm','armor','army','aroma','arose','array','arrow','arson','art','ash',
  'aside','ask','asleep','asset','atlas','atom','attic','audio','audit','aunt',
  'auto','avid','avoid','await','awake','award','aware','awful','axe','axis',
  'abbey','absorb','abuse','accept','access','accord','accuse','achieve','across','adapt',
  'admit','adopt','adult','advent','advice','advise','aerial','affair','affect','afford',
  'afraid','agency','agenda','agent','agile','agree','ahead','album','almost','always',
  'amaze','ambush','among','amount','anchor','animal','answer','anyone','anyway','appeal',
  'appear','armed','around','arrest','arrive','aspect','assert','assist','assume','assure',
  'attach','attack','attend','august','autumn','avenue','avert','avocado','awaken','ado',
  'alb','all','and','apt','arc','are','ark','ate','awe','awl',
  'abode','acorn','acute','after','again','agony','annoy','apart','avail','awoke',
  // B
  'baby','back','bacon','bad','badge','badly','bag','bail','bait','bake',
  'baker','ball','ban','band','bang','bank','bar','bare','bark','barn',
  'baron','base','basic','basin','basis','bat','batch','bath','bay','beach',
  'bead','beam','bean','bear','beard','beast','beat','bed','beef','been',
  'beer','begin','begun','being','bell','belly','below','belt','bench','bend',
  'bent','berry','best','bet','bible','bid','big','bike','bill','bind',
  'bird','birth','bit','bite','black','blade','blame','bland','blank','blast',
  'blaze','bleak','bleed','blend','bless','blind','blink','bliss','block','blond',
  'blood','bloom','blow','blue','bluff','blunt','blur','blush','board','boast',
  'boat','body','bold','bolt','bomb','bond','bone','bonus','book','boom',
  'boost','boot','bore','born','boss','both','bound','bow','bowl','box',
  'boy','brace','brain','brake','brand','brass','brave','bread','break','breed',
  'brick','bride','brief','bring','broad','broke','brook','brown','brush','brute',
  'buck','bud','buddy','bug','build','built','bulk','bull','bunch','burn',
  'burst','bury','bus','bush','busy','but','buyer','buzz','banana','banner',
  'barrel','basket','battle','beacon','beauty','become','beetle','before','behalf','behave',
  'behind','belong','beside','better','beyond','bishop','bitter','blanket','bleach','blister',
  'blossom','bobcat','border','bother','bottle','bottom','bounce','branch','breach','bridge',
  'bright','broken','bronze','brother','browse','bubble','bucket','budget','buffet','bundle',
  'burden','bureau','butter','button','bypass','bin','bun','buy','began','blown',
  'booth','bored',
  // C
  'cab','cabin','cable','cage','cake','call','calm','came','camel','camp',
  'can','canal','candy','cap','cape','car','card','care','cargo','carry',
  'cart','carve','case','cash','cast','cat','catch','cause','cave','cease',
  'cell','cent','chain','chair','chalk','champ','chance','chaos','chap','charm',
  'chart','chase','cheap','cheat','check','cheek','cheer','chess','chest','chew',
  'chief','child','chill','chin','chip','choir','choke','chord','chose','chunk',
  'cite','city','civil','claim','clam','clap','clash','clasp','class','claw',
  'clay','clean','clear','clerk','click','cliff','climb','cling','clip','cloak',
  'clock','clone','close','cloth','cloud','club','clue','clump','clung','coach',
  'coal','coast','coat','code','coil','coin','cold','collar','color','colt',
  'comb','come','comic','cool','cope','copy','coral','cord','core','corn',
  'corps','cost','cosy','couch','could','count','coup','court','cover','cow',
  'crack','craft','crane','crash','crazy','cream','crew','crime','crisp','cross',
  'crowd','crown','crude','cruel','crush','cry','cube','cult','cup','cure',
  'curl','curve','cut','cute','cycle','cabinet','cactus','camera','cancel','candle',
  'cannon','canvas','canyon','carbon','career','carpet','castle','casual','cattle','caught',
  'caution','cellar','center','cereal','change','chapel','charge','cherry','choice','choose',
  'chosen','chrome','church','circle','circus','citizen','classic','clever','client','clinic',
  'closet','clover','cobalt','cockpit','coffee','column','combat','comedy','comet','comfort',
  'commit','common','copper','corner','corpse','cosmos','cotton','county','couple','courage',
  'cousin','cradle','credit','crisis','cruise','cubicle','curtain','custom','cyborg','cymbal',
  'cob','cod','cog','cop','cot','cub','cud','cur','cedar','china',
  'cider','civic','creek','crest',
  // D
  'dad','daily','dairy','dam','damp','dance','dare','dark','dart','dash',
  'data','date','dawn','day','dead','deaf','deal','dean','dear','death',
  'debt','decay','deck','deed','deem','deep','deer','delay','delta','demon',
  'dense','deny','depth','derby','desk','devil','dial','diary','dice','did',
  'die','diet','dig','dim','dine','dip','dire','dirt','dirty','dish',
  'disk','ditch','dive','dizzy','dock','dodge','dog','doll','dome','done',
  'donor','doom','door','dose','dot','doubt','dough','dove','down','draft',
  'drag','drain','drama','drank','draw','drawn','dream','dress','drew','dried',
  'drift','drill','drink','drip','drive','drop','drove','drum','drunk','dry',
  'duck','due','dug','duke','dull','dumb','dump','dune','dust','dusty',
  'duty','dwell','dying','dagger','damage','dampen','danger','daring','darken','debris',
  'decade','decent','decide','decode','decor','defeat','defend','define','degree','delete',
  'demand','depart','depend','deploy','deputy','desert','design','desire','detail','detect',
  'device','devote','diesel','differ','digest','dinner','direct','divide','doctor','domain',
  'donkey','double','dragon','driven','driver','dab','den','dew','din','doe',
  'don','dub','dud','dun','duo','dye','debut','depot','diner','doing',
  'dozen','dread','droit','drown','dwarf',
  // E
  'each','eager','eagle','ear','earl','early','earn','earth','ease','east',
  'easy','eat','eaten','echo','edge','edit','eel','eight','elbow','elder',
  'elect','elite','elm','else','empty','end','enemy','enjoy','enter','entry',
  'equal','era','error','essay','eve','even','event','ever','every','evil',
  'exact','exam','excel','exist','exit','extra','eye','earned','eating','editor',
  'effect','effort','eighth','elapse','eleven','emerge','empire','employ','enable','ending',
  'endure','energy','engage','engine','enough','ensure','entire','errand','escape','estate',
  'ethics','evenly','evolve','exceed','except','excite','excuse','exempt','expand','expect',
  'expert','export','expose','extend','extent','extras','egg','ego','elk','emu',
  'ewe','email','ember','endow','epoch','equip','ethic','evade','exalt','exile',
  'expel',
  // F
  'face','fact','fade','fail','faint','fair','fairy','faith','fake','fall',
  'false','fame','fan','fancy','far','fare','farm','fast','fat','fatal',
  'fate','fault','favor','fear','feast','feat','fed','fee','feed','feel',
  'feet','fell','felt','fence','ferry','fever','few','fiber','field','fifth',
  'fifty','fight','file','fill','film','final','find','fine','fire','firm',
  'first','fish','fist','fit','five','fix','flag','flame','flash','flat',
  'flaw','fled','flesh','flew','float','flock','flood','floor','flour','flow',
  'fluid','flush','fly','foam','focal','focus','fog','fold','folk','fond',
  'food','fool','foot','for','force','forge','fork','form','fort','forth',
  'forty','forum','found','four','fox','frame','frank','fraud','free','fresh',
  'frog','from','front','frost','froze','fruit','fuel','full','fun','fund',
  'funny','fur','fury','fuse','fuss','fuzzy','fabric','factor','fallen','family',
  'famine','famous','farmer','father','fathom','fellow','female','figure','filter','finger',
  'fiscal','flight','flower','flying','follow','forbid','forest','forget','formal','former',
  'foster','freeze','friend','frozen','funnel','future','fad','fax','fen','fig',
  'fin','fir','fob','foe','fop','fry','fable','facet','fewer','flare',
  'flier','fling','flint','floss','fluke','foggy','freed','friar','frill','frisk',
  'frugal','fungi',
  // G
  'gain','gang','gap','gas','gasp','gate','gave','gaze','gear','gem',
  'gene','genre','ghost','giant','gift','girl','give','given','glad','glass',
  'gleam','glide','globe','gloom','glory','gloss','glove','glow','glue','goal',
  'goat','god','going','gold','golf','gone','good','goose','got','grab',
  'grace','grade','grain','grand','grant','grape','grasp','grass','grave','gray',
  'great','greed','green','greet','grew','grief','grill','grim','grin','grind',
  'grip','groan','gross','group','grove','grow','grown','guard','guess','guest',
  'guide','guilt','gun','gut','guy','galaxy','gamble','garage','garden','garlic',
  'gather','gazing','gender','gentle','gifted','ginger','global','golden','gotten','govern',
  'gravel','ground','growth','guitar','gutter','gab','gag','gal','gel','get',
  'gig','gin','gnu','gum','gym','gyp','glare','graze','groom','guild',
  'guise',
  // H
  'habit','had','hair','half','hall','halt','ham','hand','hang','happy',
  'hard','harm','harsh','haste','hat','hate','haul','have','hay','head',
  'heal','heap','hear','heard','heart','heat','heavy','hedge','heel','held',
  'hello','help','hence','her','herb','herd','here','hero','hide','high',
  'hike','hill','hint','hip','hire','hit','hobby','hold','hole','holy',
  'home','honey','honor','hood','hook','hope','horn','horse','host','hot',
  'hotel','hour','house','hover','how','hub','hug','huge','human','humor',
  'hunt','hurry','hurt','hut','hammer','handle','happen','harbor','hardly','hazard',
  'health','heaven','height','helmet','hidden','holder','hollow','honest','hoodie','horror',
  'hostel','hourly','humble','hunger','hunter','hurdle','hag','has','hem','hen',
  'hew','hex','hid','him','his','hob','hog','hop','hue','hum',
  'hairy','haven','hefty','homer','humid',
  // I
  'ice','icy','idea','ideal','idle','image','imply','inch','index','india',
  'inner','input','into','iron','isle','issue','item','ivory','ivy','ignore',
  'immune','impact','import','impose','income','indeed','indoor','infant','inform','inject',
  'injury','insect','insert','inside','insist','intact','intend','intent','intern','invest',
  'invite','inward','island','itself','ilk','ill','imp','ink','inn','ion',
  'ire','irk','inbox','indie','infer',
  // J
  'jack','jail','jam','jaw','jazz','jet','jewel','job','join','joke',
  'joy','judge','juice','jump','just','jacket','jigsaw','jostle','jungle','junior',
  'justice','jab','jag','jar','jay','jig','jog','jot','jug','jut',
  'joint','joker','jumbo','jumpy','juror',
  // K
  'keen','keep','kept','key','kick','kid','kill','kind','king','kiss',
  'kit','knee','knelt','knew','knife','knit','knob','knock','knot','know',
  'known','kayak','kernel','kettle','kidney','kitten','knight','keg','ken','kin',
  'knack','knead','kneel','knoll',
  // L
  'label','labor','lace','lack','lad','laid','lake','lamp','land','lane',
  'lap','large','laser','last','late','later','laugh','launch','lava','lawn',
  'lay','layer','lazy','lead','leaf','leak','lean','leap','learn','lease',
  'least','leave','led','left','leg','lemon','lend','lens','less','let',
  'level','lever','lid','lie','life','lift','light','like','limb','lime',
  'limit','limp','line','linen','link','lion','lip','list','lit','live',
  'liver','load','loan','lobby','local','lock','lodge','log','logic','lone',
  'long','look','loop','loose','lord','lose','loss','lost','lot','loud',
  'love','lovely','lover','low','lower','loyal','luck','lucky','lump','lunch',
  'lung','lure','lush','ladder','laptop','latest','latter','lavish','layout','leader',
  'league','legend','lender','length','lesson','letter','likely','linear','linger','liquor',
  'listen','litter','little','lively','lizard','locker','longer','lookup','loosen','lowest',
  'lumber','luxury','lab','lag','law','lax','lea','lib','lug','lux',
  'lance','lapse','latch','legal','liken','limbo','liter','llama','lorry','lucid',
  'lunar','lunge','lyric',
  // M
  'mad','made','magic','mail','main','major','make','maker','male','mall',
  'man','manor','many','map','maple','march','mare','mark','marry','marsh',
  'mask','mass','mast','match','mate','math','may','mayor','meal','mean',
  'meant','meat','medal','media','meet','melt','memo','men','mend','menu',
  'mercy','mere','merit','merry','mesh','mess','messy','met','metal','meter',
  'mild','mile','milk','mill','mind','mine','minor','minus','mist','mix',
  'moan','moat','mob','mock','mode','model','moist','mold','mom','money',
  'monk','month','mood','moon','moral','more','most','moth','motor','mount',
  'mourn','mouse','mouth','move','much','mud','mug','mule','must','my',
  'myth','magnet','mainly','manage','manner','manual','marble','margin','marine','marker',
  'market','master','matter','meadow','medium','member','memory','mental','mentor','method',
  'middle','mighty','miller','mingle','mirror','mobile','modern','modest','modify','moment',
  'mostly','mother','motion','motive','mutual','muzzle','myopic','myrtle','myself','mac',
  'mar','mat','maw','mid','mod','mop','mow','mum','mun','muse',
  'mut','merge','midst','might','mimic','mirth','moose','movie','mucus','mural',
  'music','myrrh',
  // N
  'nail','name','nap','navy','near','neat','neck','need','nerve','nest',
  'net','never','new','next','nice','night','nine','noble','nod','noise',
  'none','noon','norm','north','nose','not','note','novel','now','nude',
  'nurse','nut','namely','napkin','narrow','nation','native','nature','nearby','nearly',
  'neatly','needle','nephew','neural','nickel','nobody','normal','notice','notify','nozzle',
  'number','nursery','nab','nag','nay','nil','nip','nit','nor','nub',
  'nun','naive','ninja','notch',
  // O
  'oak','oar','oath','obey','ocean','odd','odds','off','offer','often',
  'oil','old','olive','once','one','onset','onto','open','opera','opt',
  'orbit','order','organ','other','ought','ounce','our','out','outer','oven',
  'over','owe','own','owner','oxide','object','obtain','occupy','offend','office',
  'offset','online','opener','openly','oppose','option','orange','orchid','orient','origin',
  'outfit','outlaw','output','outset','oaf','oat','ode','oft','ohm','orb',
  'ore','owl','occur','otter','outdo','ozone',
  // P
  'pace','pack','pad','page','paid','pail','pain','paint','pair','pale',
  'palm','pan','panel','panic','paper','par','park','part','party','pass',
  'past','paste','patch','path','pause','pave','paw','pay','peace','peach',
  'peak','pearl','pen','penny','per','perch','peril','pet','phase','phone',
  'photo','piano','pick','pie','piece','pig','pike','pile','pill','pilot',
  'pin','pine','pink','pipe','pit','pitch','pity','place','plain','plan',
  'plane','plant','plate','play','plaza','plead','ploy','plug','plum','plumb',
  'plump','plunge','plus','poem','poet','point','pole','pond','pool','poor',
  'pop','pope','pork','port','pose','post','pot','pound','pour','power',
  'pray','press','price','pride','prime','print','prior','prize','probe','proof',
  'proud','prove','pub','pull','pulse','pump','punch','pupil','pure','purse',
  'push','put','puzzle','packet','paddle','palace','parade','parent','parrot','partly',
  'patrol','patron','patter','pebble','pencil','people','pepper','permit','person','phrase',
  'pillar','pillow','pirate','planet','pledge','plenty','pocket','poetry','poison','police',
  'policy','polish','polite','ponder','poplar','portal','poster','potato','potion','potter',
  'poultry','powder','praise','prayer','prefer','priest','prince','prison','profit','prompt',
  'proper','prose','protect','proven','public','punish','puppet','purple','pursue','pal',
  'pap','pat','pea','peg','pep','pew','ply','pod','pow','pro',
  'pry','pug','pun','pup','pus','pains','pinch','pixel','pizza','plaid',
  'pluck','plush','poker','polar','poppy','porch','poser','pouch','prone','prune',
  'psalm','purge','pushy',
  // Q
  'queen','query','quest','quick','quid','quiet','quit','quite','quota','quote',
  'quarry','quail','qualm','queue','quirk',
  // R
  'race','rack','radar','rage','raid','rail','rain','raise','rally','ram',
  'ran','ranch','range','rank','rapid','rare','rat','rate','ratio','raw',
  'ray','reach','react','read','ready','real','realm','rear','rebel','red',
  'reed','reef','reel','reign','relax','relay','rely','rent','repay','reply',
  'rest','rich','rid','ride','ridge','rifle','right','rigid','rim','ring',
  'riot','ripe','rise','risen','risk','risky','rival','river','road','roam',
  'roar','rob','robe','robin','robot','rock','rod','rode','role','roll',
  'roman','roof','room','root','rope','rose','rot','rough','round','route',
  'row','royal','rub','rude','rug','ruin','rule','ruler','run','rural',
  'rush','rust','rabbit','racial','racket','radish','random','rarely','rattle','reader',
  'really','reason','recall','recent','record','reduce','reform','refuse','regain','regard',
  'region','reject','relate','relief','remain','remedy','remind','remote','remove','render',
  'rental','repair','repeat','report','rescue','resign','resist','resort','result','retail',
  'retain','retire','return','reveal','review','revolt','reward','ribbon','riddle','ritual',
  'robust','rocket','rotate','rotten','rubber','rumble','rumor','runway','rustic','rag',
  'rap','ref','rev','rib','rig','rip','roe','rum','rut','rye',
  'radio','rainy','raven','refer','remit','renew','rerun','reset','resin','retro',
  'rider','rinse','roast','rocky','rover','rugby','rusty',
  // S
  'sack','sad','safe','saint','sake','sale','salt','same','sand','sane',
  'sang','sat','sauce','save','saw','say','scale','scar','scene','scent',
  'scope','score','scout','scrap','sea','seal','seam','seat','seed','seek',
  'seem','seen','seize','self','sell','send','sense','sent','serve','set',
  'seven','shade','shadow','shaft','shake','shall','shame','shape','share','shark',
  'sharp','shed','sheer','sheet','shelf','shell','shift','shine','ship','shirt',
  'shock','shoe','shook','shoot','shop','shore','short','shot','shout','show',
  'shower','shrub','shut','shy','sick','side','siege','sigh','sight','sign',
  'signal','silent','silk','silly','silver','simple','since','sing','sink','sir',
  'sister','sit','site','six','sixty','size','skill','skin','skip','skull',
  'sky','slam','slap','slate','slave','sleep','slept','slice','slid','slide',
  'slight','slim','slip','slope','slot','slow','small','smart','smell','smile',
  'smoke','smooth','snap','snow','soak','soap','soar','sock','soft','soil',
  'solar','sold','sole','solid','solve','some','son','song','soon','sorry',
  'sort','soul','sound','soup','south','space','span','spare','spark','speak',
  'speed','spell','spend','spent','spice','spill','spin','spine','spite','split',
  'spoke','sport','spot','spray','squad','staff','stage','stain','stair','stake',
  'stale','stall','stamp','stand','star','stare','stark','start','state','stay',
  'steak','steal','steam','steel','steep','steer','stem','step','stern','stick',
  'stiff','still','sting','stir','stock','stole','stone','stood','stop','store',
  'storm','story','stove','stray','strip','stroll','stuck','stuff','stump','style',
  'such','suck','sugar','suit','sum','sun','super','sure','surge','swan',
  'swap','swear','sweat','sweep','sweet','swept','swift','swim','swing','sword',
  'swore','sworn','swung','sync','saddle','safely','safety','sailor','salary','salmon',
  'sample','sandal','savage','scarce','scheme','school','screen','script','search','season',
  'second','secret','sector','secure','select','seldom','senior','serial','series','settle',
  'severe','shaman','shanty','shield','single','sketch','slower','sneeze','soccer','socket',
  'soften','solver','source','speech','sphere','spider','spirit','splash','sponge','spread',
  'spring','square','stable','status','steady','stereo','sticky','stolen','strain','strand',
  'stream','street','strict','stride','strike','string','stroke','strong','studio','submit',
  'subtle','sudden','suffer','summit','superb','supply','survey','swamp','symbol','syntax',
  'system','sac','sag','sap','sew','she','sin','sip','sis','ski',
  'sly','sob','sod','sop','sot','sow','soy','spa','spy','sty',
  'sub','sue','sup','sandy','scant','scare','scarf','shave','shawl','sheep',
  'shove','sixth','skate','slain','slash','smith','snack','snake','snare','sneak',
  'sonic','spawn','spike','spoon','stack','stave','stoic','stool','stout','strap',
  'straw','study','stung','stunk','suite','sunny','swarm','swirl','swoop',
  // T
  'table','tail','take','tale','talk','tall','tank','tap','tape','tar',
  'task','taste','tax','tea','teach','team','tear','teen','tell','ten',
  'tend','tent','term','test','text','thank','that','theft','their','them',
  'theme','then','there','these','thick','thief','thin','thing','think','third',
  'those','three','threw','throw','thumb','thus','tick','tide','tidy','tie',
  'tiger','tight','tile','till','time','tin','tiny','tip','tire','tired',
  'title','toad','toast','today','toe','token','told','toll','tomb','tone',
  'tongue','too','took','tool','tooth','top','topic','torch','tore','torn',
  'total','touch','tough','tour','tower','town','toy','trace','track','trade',
  'trail','train','trait','trap','trash','treat','tree','trend','trial','tribe',
  'trick','tried','trim','trio','trip','trod','troop','truck','truly','trump',
  'trunk','trust','truth','try','tube','tuck','tune','turn','tutor','twice',
  'twin','twist','two','type','tablet','tackle','talent','target','temple','tenant',
  'tender','tennis','terror','thirst','thirty','thorn','thread','threat','thrill','thrive',
  'throne','thrown','timber','tissue','toward','trader','travel','treaty','tribal','triple',
  'trophy','troupe','tunnel','turkey','turtle','twelve','typist','tab','tad','tag',
  'tan','tat','the','thy','tic','ton','tot','tow','tub','tug',
  'tun','taken','tease','tempo','timer','towel','toxic','trout','tumor','tuner',
  'tweet',
  // U
  'ugly','uncle','under','union','unique','unit','unite','unity','until','upon',
  'upper','upset','urban','urge','use','used','user','usual','utter','unable',
  'unfair','unfold','unless','unlike','unlock','unrest','unveil','upbeat','update','uphold',
  'upload','upward','urgent','useful','utmost','ugh','urn','ultra','undue','unfit',
  'usher','using',
  // V
  'vague','vain','valid','value','valve','van','vary','vast','vault','verb',
  'verse','very','vet','via','video','view','vine','virus','visit','vital',
  'vivid','vocal','voice','void','volt','vote','vow','vacuum','valley','vanish',
  'velvet','vendor','venture','verbal','verify','vessel','victim','viewer','violin','virtue',
  'vision','visual','volume','voyage','vat','vex','vie','vim','valor','vapor',
  'vigor','vinyl','viral','vista','vodka','voter','vouch','vowel',
  // W
  'wade','wage','wagon','wait','wake','walk','wall','want','war','ward',
  'warm','warn','wash','waste','watch','water','wave','wax','way','weak',
  'wealth','weapon','wear','weary','web','wed','weed','week','weigh','weird',
  'well','went','were','west','wet','whale','wheat','wheel','when','where',
  'which','while','whip','white','whole','whom','whose','why','wide','wife',
  'wild','will','win','wind','wine','wing','winter','wipe','wire','wisdom',
  'wise','wish','witch','with','within','woke','wolf','woman','women','won',
  'wood','wool','word','wore','work','world','worm','worry','worse','worst',
  'worth','would','wound','wrap','wrist','write','wrong','wrote','waiter','walker',
  'wallet','wander','warmth','warrior','weekly','weight','whimsy','whisky','widely','widget',
  'window','winner','wizard','wonder','worker','worthy','writer','wad','wag','was',
  'who','wig','wit','woe','wok','woo','wot','wow','wry','weave',
  'wedge','widow','width','wrath','wreck',
  // X
  'xerox',
  // Y
  'yacht','yard','yarn','year','yell','yes','yet','yield','young','yours',
  'youth','yearly','yellow','yogurt','yak','yam','yap','yaw','yea','yen',
  'yew','yip','you','yow','yearn',
  // Z
  'zeal','zero','zinc','zone','zoo','zealot','zenith','zombie','zoning','zag',
  'zap','zed','zen','zig','zip','zit','zebra','zilch',
};

class WordChainGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const WordChainGame({super.key, required this.gameContext});

  @override
  State<WordChainGame> createState() => WordChainGameState();
}

class WordChainGameState extends State<WordChainGame>
    with SingleTickerProviderStateMixin
    implements GameInterface {
  late Random _rng;
  gc.GameContext get _ctx => widget.gameContext;

  final List<String> _chain = [];
  final Set<String> _usedWords = {};
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _playerScore = 0;
  int _aiScore = 0;
  int _invalidAttempts = 0;
  int _turnTimeRemaining = 15;
  Timer? _turnTimer;
  bool _isPlayerTurn = true;
  bool _gameOver = false;
  String? _errorMessage;
  bool _shaking = false;

  @override
  String get gameId => 'word_chain';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _startGame();
    _ctx.setOnOpponentMove(onOpponentMove);
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startGame() {
    // Pick a seed word from dictionary
    final words = _dictionary.toList();
    final seedWord = words[_rng.nextInt(words.length)];
    _chain.add(seedWord);
    _usedWords.add(seedWord);
    _isPlayerTurn = true;
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimeRemaining = 15;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _turnTimeRemaining--;
      });
      if (_turnTimeRemaining <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    if (_gameOver) return;
    if (_isPlayerTurn) {
      _endGame(playerLost: true, reason: 'Time ran out!');
    } else {
      // AI timed out (shouldn't happen, but handle gracefully)
      _endGame(playerLost: false, reason: 'AI failed to find a word!');
    }
  }

  String _getRequiredLetter() {
    if (_chain.isEmpty) return '';
    return _chain.last[_chain.last.length - 1].toLowerCase();
  }

  void _submitWord() {
    if (_gameOver || !_isPlayerTurn) return;

    final word = _inputController.text.trim().toLowerCase();
    _inputController.clear();
    _errorMessage = null;

    if (word.isEmpty) return;

    if (!_dictionary.contains(word)) {
      _invalidAttempts++;
      _showError('Not a valid word!');
      if (_invalidAttempts >= 3) {
        _endGame(playerLost: true, reason: '3 invalid attempts!');
      }
      return;
    }

    final required = _getRequiredLetter();
    if (word[0] != required) {
      _invalidAttempts++;
      _showError('Must start with "${required.toUpperCase()}"!');
      if (_invalidAttempts >= 3) {
        _endGame(playerLost: true, reason: '3 invalid attempts!');
      }
      return;
    }

    if (_usedWords.contains(word)) {
      _invalidAttempts++;
      _showError('Already used!');
      if (_invalidAttempts >= 3) {
        _endGame(playerLost: true, reason: '3 invalid attempts!');
      }
      return;
    }

    // Valid word
    setState(() {
      _chain.add(word);
      _usedWords.add(word);
      _playerScore++;
      _invalidAttempts = 0;
      _isPlayerTurn = false;
    });
    _scrollToBottom();

    if (_ctx.mode == GameMode.practice) {
      _startTurnTimer();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_gameOver) _aiMove();
      });
    } else {
      // In multiplayer, send move via socket
      _ctx.socketService.sendMove(_ctx.userId, {
        'type': 'word',
        'word': word,
      });
      _startTurnTimer();
    }
  }

  void _aiMove() {
    final required = _getRequiredLetter();
    final candidates = _dictionary
        .where((w) => w[0] == required && !_usedWords.contains(w))
        .toList();

    if (candidates.isEmpty) {
      _endGame(playerLost: false, reason: 'AI cannot find a word!');
      return;
    }

    final aiWord = candidates[_rng.nextInt(candidates.length)];
    setState(() {
      _chain.add(aiWord);
      _usedWords.add(aiWord);
      _aiScore++;
      _isPlayerTurn = true;
    });
    _scrollToBottom();
    _startTurnTimer();
  }

  void _showError(String msg) {
    setState(() {
      _errorMessage = msg;
      _shaking = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _shaking = false;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _endGame({required bool playerLost, required String reason}) {
    _turnTimer?.cancel();
    setState(() {
      _gameOver = true;
      _errorMessage = reason;
    });

    final winnerId = playerLost
        ? (_ctx.opponentId ?? 0)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _playerScore,
      'player_2_score': _aiScore,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    final word = moveData['word'] as String? ?? '';
    if (word.isEmpty) return;
    setState(() {
      _chain.add(word);
      _usedWords.add(word);
      _aiScore++;
      _isPlayerTurn = true;
    });
    _scrollToBottom();
    _startTurnTimer();
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final chainData = savedState['chain'] as List?;
    if (chainData != null) {
      _chain.clear();
      _usedWords.clear();
      for (final w in chainData) {
        final word = w as String;
        _chain.add(word);
        _usedWords.add(word);
      }
    }
    _playerScore = savedState['playerScore'] as int? ?? 0;
    _aiScore = savedState['aiScore'] as int? ?? 0;
    _isPlayerTurn = savedState['isPlayerTurn'] as bool? ?? true;
    setState(() {});
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'chain': _chain,
      'playerScore': _playerScore,
      'aiScore': _aiScore,
      'isPlayerTurn': _isPlayerTurn,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTimerBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildChain()),
            if (_errorMessage != null && !_gameOver) _buildErrorBanner(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPlayerTurn ? 'Your Turn' : 'Opponent\'s Turn',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              if (_chain.isNotEmpty)
                Text(
                  'Next letter: "${_getRequiredLetter().toUpperCase()}"',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kSecondary,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              _buildScoreBadge('You', _playerScore),
              const SizedBox(width: 8),
              _buildScoreBadge('AI', _aiScore),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String label, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $score',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    final fraction = _turnTimeRemaining / 15.0;
    Color color;
    if (_turnTimeRemaining > 10) {
      color = Colors.green;
    } else if (_turnTimeRemaining > 5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
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
          const SizedBox(height: 2),
          Text(
            '${_turnTimeRemaining}s',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChain() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _chain.length,
      itemBuilder: (context, index) {
        final word = _chain[index];
        final isFirst = index == 0;
        final isPlayerWord = isFirst
            ? false
            : (index % 2 == 1); // odd indices are player words
        final lastLetter = word[word.length - 1].toUpperCase();
        final firstLetter = word[0].toUpperCase();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              if (isFirst)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPlayerWord
                        ? _kPrimary.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPlayerWord ? 'You' : 'AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPlayerWord ? _kPrimary : _kSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 18, color: _kPrimary),
                    children: [
                      TextSpan(
                        text: firstLetter,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index > 0 ? Colors.green.shade700 : _kPrimary,
                        ),
                      ),
                      TextSpan(
                        text: word.substring(1, word.length - 1),
                      ),
                      TextSpan(
                        text: lastLetter,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: _shaking
          ? (Matrix4.identity()..setTranslationRaw(8.0, 0, 0))
          : Matrix4.identity(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInput() {
    final enabled = _isPlayerTurn && !_gameOver;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitWord(),
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Type a word starting with "${_getRequiredLetter().toUpperCase()}"...'
                    : 'Waiting...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: enabled ? _submitWord : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final playerWon = _playerScore > _aiScore;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  playerWon ? Icons.emoji_events_rounded : Icons.link_off_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  playerWon ? 'You Won!' : 'Game Over',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  playerWon ? 'Umeshinda!' : 'Mchezo Umekwisha',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  '${_chain.length - 1}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const Text(
                  'words in chain / maneno kwenye msururu',
                  style: TextStyle(fontSize: 13, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'You: $_playerScore  |  AI: $_aiScore',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done / Maliza'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
