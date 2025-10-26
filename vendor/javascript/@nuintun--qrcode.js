// @nuintun/qrcode@5.0.2 downloaded from https://ga.jspm.io/npm:@nuintun/qrcode@5.0.2/esm/index.js

/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */
const t=new Map;function fromCharsetValue(e){const n=t.get(e);if(n!=null)return n;throw Error("illegal charset value")}class Charset{#t;#e;static CP437=new Charset("cp437",2,0);static ISO_8859_1=new Charset("iso-8859-1",3,1);static ISO_8859_2=new Charset("iso-8859-2",4);static ISO_8859_3=new Charset("iso-8859-3",5);static ISO_8859_4=new Charset("iso-8859-4",6);static ISO_8859_5=new Charset("iso-8859-5",7);static ISO_8859_6=new Charset("iso-8859-6",8);static ISO_8859_7=new Charset("iso-8859-7",9);static ISO_8859_8=new Charset("iso-8859-8",10);static ISO_8859_9=new Charset("iso-8859-9",11);static ISO_8859_10=new Charset("iso-8859-10",12);static ISO_8859_11=new Charset("iso-8859-11",13);static ISO_8859_13=new Charset("iso-8859-13",15);static ISO_8859_14=new Charset("iso-8859-14",16);static ISO_8859_15=new Charset("iso-8859-15",17);static ISO_8859_16=new Charset("iso-8859-16",18);static SHIFT_JIS=new Charset("shift-jis",20);static CP1250=new Charset("cp1250",21);static CP1251=new Charset("cp1251",22);static CP1252=new Charset("cp1252",23);static CP1256=new Charset("cp1256",24);static UTF_16BE=new Charset("utf-16be",25);static UTF_8=new Charset("utf-8",26);static ASCII=new Charset("ascii",27);static BIG5=new Charset("big5",28);static GB2312=new Charset("gb2312",29);static EUC_KR=new Charset("euc-kr",30);static GBK=new Charset("gbk",31);static GB18030=new Charset("gb18030",32);static UTF_16LE=new Charset("utf-16le",33);static UTF_32BE=new Charset("utf-32be",34);static UTF_32LE=new Charset("utf-32le",35);static ISO_646_INV=new Charset("iso-646-inv",170);static BINARY=new Charset("binary",899);
/**
   * @constructor
   * @param label The label of charset.
   * @param values The values of charset.
   */
constructor(e,...n){this.#t=e;this.#e=Object.freeze(n);for(const e of n){if(!(e>=0&&e<=999999&&Number.isInteger(e)))throw new Error("illegal extended channel interpretation value");t.set(e,this)}}get label(){return this.#t}get values(){return this.#e}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Decoded{#n;#s;#o;#r;#i;#c;constructor(t,e,{mask:n,level:s},o,r){this.#n=n;this.#s=s;this.#o=r;this.#r=e;this.#c=t;this.#i=o}get mask(){return this.#n}get level(){return this.#s.name}get version(){return this.#r.version}get mirror(){return this.#o}get content(){return this.#c.content}get corrected(){return this.#i}get symbology(){return this.#c.symbology}get fnc1(){return this.#c.fnc1}get codewords(){return this.#c.codewords}get structured(){return this.#c.structured}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function toBit(t){return t&1}function toInt32(t){return t|0}function round(t){return toInt32(t+(t<0?-.5:.5))}function getBitMask(t){return 1<<getBitOffset(t)}function getBitOffset(t){return t&31}function charAt(t,e){const n=t.at(e);return n!=null?n:""}function hammingWeight(t){t-=t>>1&1431655765;t=(t&858993459)+(t>>2&858993459);return 16843009*(t+(t>>4)&252645135)>>24}function findMSBSet(t){return 32-Math.clz32(t)}function calculateBCHCode(t,e){const n=findMSBSet(e);t<<=n-1;while(findMSBSet(t)>=n)t^=e<<findMSBSet(t)-n;return t}function accumulate(t,e=0,n=t.length){let s=0;for(let o=e;o<n;o++)s+=t[o];return s}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class BitSource{#a;#l;#u;constructor(t){this.#a=t;this.#l=0;this.#u=0}get bitOffset(){return this.#l}get byteOffset(){return this.#u}read(t){let e=0;let n=this.#l;let s=this.#u;const o=this.#a;if(n>0){const r=8-n;const i=Math.min(t,r);const c=r-i;const a=255>>8-i<<c;t-=i;n+=i;e=(o[s]&a)>>c;if(n===8){s++;n=0}}if(t>0){while(t>=8){t-=8;e=e<<8|o[s++]&255}if(t>0){const r=8-t;const i=255>>r<<r;n+=t;e=e<<t|(o[s]&i)>>r}}this.#l=n;this.#u=s;return e}available(){return 8*(this.#a.length-this.#u)-this.#l}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const e=new Map;function fromModeBits(t){const n=e.get(t);if(n!=null)return n;throw new Error("illegal mode bits")}class Mode{#w;#h;static TERMINATOR=new Mode([0,0,0],0);static NUMERIC=new Mode([10,12,14],1);static ALPHANUMERIC=new Mode([9,11,13],2);static STRUCTURED_APPEND=new Mode([0,0,0],3);static BYTE=new Mode([8,16,16],4);static ECI=new Mode([0,0,0],7);static KANJI=new Mode([8,10,12],8);static FNC1_FIRST_POSITION=new Mode([0,0,0],5);static FNC1_SECOND_POSITION=new Mode([0,0,0],9);static HANZI=new Mode([8,10,12],13);constructor(t,n){this.#w=n;this.#h=new Int32Array(t);e.set(n,this)}get bits(){return this.#w}getCharacterCountBits({version:t}){let e;e=t<=9?0:t<=26?1:2;return this.#h[e]}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getMappingFromCharacters(t){let e=0;const n=new Map;for(const s of t)n.set(s,e++);return n}function getMappingFromEncodingRanges(t,...e){const n=[];const s=[];const o=new Map;const r=new TextDecoder(t,{fatal:true});for(const[t,o]of e)for(let e=t;e<=o;e++){n.push(e>>8&255,e&255);s.push(e)}const{length:i}=s;const c=r.decode(new Uint8Array(n));for(let t=0;t<i;t++){const e=charAt(c,t);o.has(e)||o.set(e,s[t])}return o}function getSerialEncodinRanges(t,e,n,s=256){const o=n.length-1;const r=[];for(let i=t;i<e;){for(let t=0;t<o;t+=2)r.push([i+n[t],i+n[t+1]]);i+=s}return r}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const n=getMappingFromEncodingRanges("gb2312",[41377,41470],[41649,41698],[41701,41710],[41713,41724],[41889,41982],[42145,42227],[42401,42486],[42657,42680],[42689,42712],[42913,42945],[42961,42993],[43169,43194],[43205,43241],[43428,43503],...getSerialEncodinRanges(45217,55038,[0,93]),[55201,55289],...getSerialEncodinRanges(55457,63486,[0,93]));const s=getMappingFromEncodingRanges("shift-jis",[33088,33150],[33152,33196],[33208,33215],[33224,33230],[33242,33256],[33264,33271],[33276,33276],[33359,33368],[33376,33401],[33409,33434],[33439,33521],[33600,33662],[33664,33686],[33695,33718],[33727,33750],[33856,33888],[33904,33918],[33920,33937],[33951,33982],[34975,35068],...getSerialEncodinRanges(35136,38908,[0,62,64,188]),[38976,39026],[39071,39164],...getSerialEncodinRanges(39232,40956,[0,62,64,188]),...getSerialEncodinRanges(57408,59900,[0,62,64,188]),[59968,60030],[60032,60068]);const o="0123456789";const r=getMappingFromCharacters(o);const i=`${o}ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:`;const c=getMappingFromCharacters(i);
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function parseECIValue(t){const e=t.read(8);if((e&128)===0)return e&127;if((e&192)===128){const n=t.read(8);return(e&63)<<8|n}if((e&224)===192){const n=t.read(16);return(e&31)<<16|n}throw new Error("illegal extended channel interpretation value")}const a=String.fromCharCode(29);function processGSCharacter(t){return t.replace(/%+/g,(t=>{const e=t.length&1;t=t.replace(/%%/g,"%");return e?t.replace(/%$/,a):t}))}function decodeAlphanumericSegment(t,e,n){let s="";while(e>1){if(t.available()<11)throw new Error("illegal bits length");const n=t.read(11);s+=charAt(i,n/45);s+=charAt(i,n%45);e-=2}if(e===1){if(t.available()<6)throw new Error("illegal bits length");s+=charAt(i,t.read(6))}return n?processGSCharacter(s):s}function decodeByteSegment(t,e,n,s,o){if(t.available()<8*e)throw new Error("illegal bits length");const r=new Uint8Array(e);const i=o!=null?fromCharsetValue(o):Charset.ISO_8859_1;for(let n=0;n<e;n++)r[n]=t.read(8);const c=n(r,i);return s?processGSCharacter(c):c}function decodeHanziSegment(t,e){if(t.available()<13*e)throw new Error("illegal bits length");let n=0;const s=new Uint8Array(2*e);while(e>0){const o=t.read(13);let r=o/96<<8|o%96;r+=r<2560?41377:42657;s[n]=r>>8&255;s[n+1]=r&255;e--;n+=2}return new TextDecoder("gb2312").decode(s)}function decodeKanjiSegment(t,e){if(t.available()<13*e)throw new Error("illegal bits length");let n=0;const s=new Uint8Array(2*e);while(e>0){const o=t.read(13);let r=o/192<<8|o%192;r+=r<7936?33088:49472;s[n]=r>>8&255;s[n+1]=r&255;e--;n+=2}return new TextDecoder("shift-jis").decode(s)}function decodeNumericSegment(t,e){let n="";while(e>=3){if(t.available()<10)throw new Error("illegal bits length");const s=t.read(10);if(s>=1e3)throw new Error("illegal numeric codeword");n+=charAt(o,s/100);n+=charAt(o,s/10%10);n+=charAt(o,s%10);e-=3}if(e===2){if(t.available()<7)throw new Error("illegal bits length");const e=t.read(7);if(e>=100)throw new Error("illegal numeric codeword");n+=charAt(o,e/10);n+=charAt(o,e%10)}else if(e===1){if(t.available()<4)throw new Error("illegal bits length");const e=t.read(4);if(e>=10)throw new Error("illegal numeric codeword");n+=charAt(o,e)}return n}function decode$1(t,e,n){let s="";let o=-1;let r;let i=false;let c=false;let a;let l=false;let u;let w=false;const h=new BitSource(t);do{a=h.available()<4?Mode.TERMINATOR:fromModeBits(h.read(4));switch(a){case Mode.TERMINATOR:break;case Mode.FNC1_FIRST_POSITION:i=true;break;case Mode.FNC1_SECOND_POSITION:c=true;o=h.read(8);break;case Mode.STRUCTURED_APPEND:if(h.available()<16)throw new Error("illegal structured append");w=Object.freeze({index:h.read(4),count:h.read(4)+1,parity:h.read(8)});break;case Mode.ECI:u=parseECIValue(h);break;default:if(a===Mode.HANZI){const t=h.read(4);if(t!==1)throw new Error("illegal hanzi subset")}const t=h.read(a.getCharacterCountBits(e));switch(a){case Mode.ALPHANUMERIC:s+=decodeAlphanumericSegment(h,t,i||c);break;case Mode.BYTE:s+=decodeByteSegment(h,t,n,i||c,u);break;case Mode.HANZI:s+=decodeHanziSegment(h,t);break;case Mode.KANJI:s+=decodeKanjiSegment(h,t);break;case Mode.NUMERIC:s+=decodeNumericSegment(h,t);break;default:throw new Error("illegal mode")}}}while(a!==Mode.TERMINATOR);i?l=Object.freeze(["GS1"]):c&&(l=Object.freeze(["AIM",o]));r=u!=null?i?4:c?6:2:i?3:c?5:1;return{content:s,codewords:t,structured:w,symbology:`]Q${r}`,fnc1:l}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const l=3;const u=3;const w=40;const h=10;function isDark(t,e,n){return t.get(e,n)===1}function applyMaskPenaltyRule1Internal(t,e){let n=0;const{size:s}=t;for(let o=0;o<s;o++){let r=-1;let i=0;for(let c=0;c<s;c++){const s=e?t.get(o,c):t.get(c,o);if(s===r)i++;else{i>=5&&(n+=l+(i-5));r=s;i=1}}i>=5&&(n+=l+(i-5))}return n}function applyMaskPenaltyRule1(t){return applyMaskPenaltyRule1Internal(t)+applyMaskPenaltyRule1Internal(t,true)}function applyMaskPenaltyRule2(t){let e=0;const n=t.size-1;for(let s=0;s<n;s++)for(let o=0;o<n;o++){const n=t.get(o,s);n===t.get(o+1,s)&&n===t.get(o,s+1)&&n===t.get(o+1,s+1)&&(e+=u)}return e}function isFourWhite(t,e,n,s,o){if(n<0||s>t.size)return false;for(let r=n;r<s;r++)if(o?isDark(t,e,r):isDark(t,r,e))return false;return true}function applyMaskPenaltyRule3(t){let e=0;const{size:n}=t;for(let s=0;s<n;s++)for(let o=0;o<n;o++){o+6<n&&isDark(t,o,s)&&!isDark(t,o+1,s)&&isDark(t,o+2,s)&&isDark(t,o+3,s)&&isDark(t,o+4,s)&&!isDark(t,o+5,s)&&isDark(t,o+6,s)&&(isFourWhite(t,s,o-4,o)||isFourWhite(t,s,o+7,o+11))&&e++;s+6<n&&isDark(t,o,s)&&!isDark(t,o,s+1)&&isDark(t,o,s+2)&&isDark(t,o,s+3)&&isDark(t,o,s+4)&&!isDark(t,o,s+5)&&isDark(t,o,s+6)&&(isFourWhite(t,o,s-4,s,true)||isFourWhite(t,o,s+7,s+11,true))&&e++}return e*w}function applyMaskPenaltyRule4(t){let e=0;const{size:n}=t;for(let s=0;s<n;s++)for(let o=0;o<n;o++)isDark(t,o,s)&&e++;const s=n*n;const o=toInt32(Math.abs(e*2-s)*10/s);return o*h}function calculateMaskPenalty(t){return applyMaskPenaltyRule1(t)+applyMaskPenaltyRule2(t)+applyMaskPenaltyRule3(t)+applyMaskPenaltyRule4(t)}function isApplyMask(t,e,n){let s;let o;switch(t){case 0:o=n+e&1;break;case 1:o=n&1;break;case 2:o=e%3;break;case 3:o=(n+e)%3;break;case 4:o=toInt32(n/2)+toInt32(e/3)&1;break;case 5:s=n*e;o=(s&1)+s%3;break;case 6:s=n*e;o=(s&1)+s%3&1;break;case 7:o=n*e%3+(n+e&1)&1;break;default:throw new Error(`illegal mask: ${t}`)}return o===0}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const f=new Map;function fromECLevelBits(t){const e=f.get(t);if(e!=null)return e;throw new Error("illegal error correction bits")}class ECLevel{#f;#w;#s;static L=new ECLevel("L",0,1);static M=new ECLevel("M",1,0);static Q=new ECLevel("Q",2,3);static H=new ECLevel("H",3,2);constructor(t,e,n){this.#w=n;this.#f=t;this.#s=e;f.set(n,this)}get bits(){return this.#w}get name(){return this.#f}get level(){return this.#s}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const d=[[21522,0],[20773,1],[24188,2],[23371,3],[17913,4],[16590,5],[20375,6],[19104,7],[30660,8],[29427,9],[32170,10],[30877,11],[26159,12],[25368,13],[27713,14],[26998,15],[5769,16],[5054,17],[7399,18],[6608,19],[1890,20],[597,21],[3340,22],[2107,23],[13663,24],[12392,25],[16177,26],[14854,27],[9396,28],[8579,29],[11994,30],[11245,31]];class FormatInfo{#n;#s;constructor(t){this.#n=t&7;this.#s=fromECLevelBits(t>>3&3)}get mask(){return this.#n}get level(){return this.#s}}function decodeFormatInfo(t,e){let n=32;let s=0;for(const[o,r]of d){if(t===o||e===o)return new FormatInfo(r);let i=hammingWeight(t^o);if(i<n){n=i;s=r}if(t!==e){i=hammingWeight(e^o);if(i<n){n=i;s=r}}}if(n<=3)return new FormatInfo(s);throw new Error("unable to decode format information")}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class ECB{#d;#C;constructor(t,e){this.#d=t;this.#C=e}get count(){return this.#d}get numDataCodewords(){return this.#C}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class ECBlocks{#B;#E;#g;#m;#p;constructor(t,...e){let n=0;let s=0;for(const{count:t,numDataCodewords:o}of e){n+=t;s+=o*t}const o=t*n;this.#B=e;this.#g=o;this.#m=s;this.#p=t;this.#E=s+o}get ecBlocks(){return this.#B}get numTotalCodewords(){return this.#E}get numTotalECCodewords(){return this.#g}get numTotalDataCodewords(){return this.#m}get numECCodewordsPerBlock(){return this.#p}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class BitMatrix{#k;#b;#y;#w;constructor(t,e=t){const n=Math.ceil(t/32);const s=n*e;this.#k=t;this.#b=e;this.#y=n;this.#w=new Int32Array(s)}#P(t,e){return e*this.#y+toInt32(t/32)}get width(){return this.#k}get height(){return this.#b}
/**
   * @method set
   * @description Set the bit value to 1 of the specified coordinate.
   * @param x The x coordinate.
   * @param y The y coordinate.
   */set(t,e){this.#w[this.#P(t,e)]|=getBitMask(t)}
/**
   * @method get
   * @description Get the bit value of the specified coordinate.
   * @param x The x coordinate.
   * @param y The y coordinate.
   */get(t,e){return toBit(this.#w[this.#P(t,e)]>>>getBitOffset(t))}flip(t,e){if(t!=null&&e!=null)this.#w[this.#P(t,e)]^=getBitMask(t);else{const t=this.#w;const{length:e}=t;for(let n=0;n<e;n++)t[n]=~t[n]}}clone(){const t=new BitMatrix(this.#k,this.#b);t.#w.set(this.#w);return t}
/**
   * @method setRegion
   * @description Set the bit value to 1 of the specified region.
   * @param left The left coordinate.
   * @param top The top coordinate.
   * @param width The width to set.
   * @param height The height to set.
   */setRegion(t,e,n,s){const o=this.#w;const r=t+n;const i=e+s;const c=this.#y;for(let n=e;n<i;n++){const e=n*c;for(let n=t;n<r;n++)o[e+toInt32(n/32)]|=getBitMask(n)}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const C=21;const B=177;const E=[31892,34236,39577,42195,48118,51042,55367,58893,63784,68472,70749,76311,79154,84390,87683,92361,96236,102084,102881,110507,110734,117786,119615,126325,127568,133589,136944,141498,145311,150283,152622,158308,161089,167017];const g=25;class Version{#M;#r;#B;#I;constructor(t,e,...n){this.#r=t;this.#B=n;this.#M=17+4*t;this.#I=e}get size(){return this.#M}get version(){return this.#r}get alignmentPatterns(){return this.#I}getECBlocks({level:t}){return this.#B[t]}}const m=[new Version(1,[],new ECBlocks(7,new ECB(1,19)),new ECBlocks(10,new ECB(1,16)),new ECBlocks(13,new ECB(1,13)),new ECBlocks(17,new ECB(1,9))),new Version(2,[6,18],new ECBlocks(10,new ECB(1,34)),new ECBlocks(16,new ECB(1,28)),new ECBlocks(22,new ECB(1,22)),new ECBlocks(28,new ECB(1,16))),new Version(3,[6,22],new ECBlocks(15,new ECB(1,55)),new ECBlocks(26,new ECB(1,44)),new ECBlocks(18,new ECB(2,17)),new ECBlocks(22,new ECB(2,13))),new Version(4,[6,26],new ECBlocks(20,new ECB(1,80)),new ECBlocks(18,new ECB(2,32)),new ECBlocks(26,new ECB(2,24)),new ECBlocks(16,new ECB(4,9))),new Version(5,[6,30],new ECBlocks(26,new ECB(1,108)),new ECBlocks(24,new ECB(2,43)),new ECBlocks(18,new ECB(2,15),new ECB(2,16)),new ECBlocks(22,new ECB(2,11),new ECB(2,12))),new Version(6,[6,34],new ECBlocks(18,new ECB(2,68)),new ECBlocks(16,new ECB(4,27)),new ECBlocks(24,new ECB(4,19)),new ECBlocks(28,new ECB(4,15))),new Version(7,[6,22,38],new ECBlocks(20,new ECB(2,78)),new ECBlocks(18,new ECB(4,31)),new ECBlocks(18,new ECB(2,14),new ECB(4,15)),new ECBlocks(26,new ECB(4,13),new ECB(1,14))),new Version(8,[6,24,42],new ECBlocks(24,new ECB(2,97)),new ECBlocks(22,new ECB(2,38),new ECB(2,39)),new ECBlocks(22,new ECB(4,18),new ECB(2,19)),new ECBlocks(26,new ECB(4,14),new ECB(2,15))),new Version(9,[6,26,46],new ECBlocks(30,new ECB(2,116)),new ECBlocks(22,new ECB(3,36),new ECB(2,37)),new ECBlocks(20,new ECB(4,16),new ECB(4,17)),new ECBlocks(24,new ECB(4,12),new ECB(4,13))),new Version(10,[6,28,50],new ECBlocks(18,new ECB(2,68),new ECB(2,69)),new ECBlocks(26,new ECB(4,43),new ECB(1,44)),new ECBlocks(24,new ECB(6,19),new ECB(2,20)),new ECBlocks(28,new ECB(6,15),new ECB(2,16))),new Version(11,[6,30,54],new ECBlocks(20,new ECB(4,81)),new ECBlocks(30,new ECB(1,50),new ECB(4,51)),new ECBlocks(28,new ECB(4,22),new ECB(4,23)),new ECBlocks(24,new ECB(3,12),new ECB(8,13))),new Version(12,[6,32,58],new ECBlocks(24,new ECB(2,92),new ECB(2,93)),new ECBlocks(22,new ECB(6,36),new ECB(2,37)),new ECBlocks(26,new ECB(4,20),new ECB(6,21)),new ECBlocks(28,new ECB(7,14),new ECB(4,15))),new Version(13,[6,34,62],new ECBlocks(26,new ECB(4,107)),new ECBlocks(22,new ECB(8,37),new ECB(1,38)),new ECBlocks(24,new ECB(8,20),new ECB(4,21)),new ECBlocks(22,new ECB(12,11),new ECB(4,12))),new Version(14,[6,26,46,66],new ECBlocks(30,new ECB(3,115),new ECB(1,116)),new ECBlocks(24,new ECB(4,40),new ECB(5,41)),new ECBlocks(20,new ECB(11,16),new ECB(5,17)),new ECBlocks(24,new ECB(11,12),new ECB(5,13))),new Version(15,[6,26,48,70],new ECBlocks(22,new ECB(5,87),new ECB(1,88)),new ECBlocks(24,new ECB(5,41),new ECB(5,42)),new ECBlocks(30,new ECB(5,24),new ECB(7,25)),new ECBlocks(24,new ECB(11,12),new ECB(7,13))),new Version(16,[6,26,50,74],new ECBlocks(24,new ECB(5,98),new ECB(1,99)),new ECBlocks(28,new ECB(7,45),new ECB(3,46)),new ECBlocks(24,new ECB(15,19),new ECB(2,20)),new ECBlocks(30,new ECB(3,15),new ECB(13,16))),new Version(17,[6,30,54,78],new ECBlocks(28,new ECB(1,107),new ECB(5,108)),new ECBlocks(28,new ECB(10,46),new ECB(1,47)),new ECBlocks(28,new ECB(1,22),new ECB(15,23)),new ECBlocks(28,new ECB(2,14),new ECB(17,15))),new Version(18,[6,30,56,82],new ECBlocks(30,new ECB(5,120),new ECB(1,121)),new ECBlocks(26,new ECB(9,43),new ECB(4,44)),new ECBlocks(28,new ECB(17,22),new ECB(1,23)),new ECBlocks(28,new ECB(2,14),new ECB(19,15))),new Version(19,[6,30,58,86],new ECBlocks(28,new ECB(3,113),new ECB(4,114)),new ECBlocks(26,new ECB(3,44),new ECB(11,45)),new ECBlocks(26,new ECB(17,21),new ECB(4,22)),new ECBlocks(26,new ECB(9,13),new ECB(16,14))),new Version(20,[6,34,62,90],new ECBlocks(28,new ECB(3,107),new ECB(5,108)),new ECBlocks(26,new ECB(3,41),new ECB(13,42)),new ECBlocks(30,new ECB(15,24),new ECB(5,25)),new ECBlocks(28,new ECB(15,15),new ECB(10,16))),new Version(21,[6,28,50,72,94],new ECBlocks(28,new ECB(4,116),new ECB(4,117)),new ECBlocks(26,new ECB(17,42)),new ECBlocks(28,new ECB(17,22),new ECB(6,23)),new ECBlocks(30,new ECB(19,16),new ECB(6,17))),new Version(22,[6,26,50,74,98],new ECBlocks(28,new ECB(2,111),new ECB(7,112)),new ECBlocks(28,new ECB(17,46)),new ECBlocks(30,new ECB(7,24),new ECB(16,25)),new ECBlocks(24,new ECB(34,13))),new Version(23,[6,30,54,78,102],new ECBlocks(30,new ECB(4,121),new ECB(5,122)),new ECBlocks(28,new ECB(4,47),new ECB(14,48)),new ECBlocks(30,new ECB(11,24),new ECB(14,25)),new ECBlocks(30,new ECB(16,15),new ECB(14,16))),new Version(24,[6,28,54,80,106],new ECBlocks(30,new ECB(6,117),new ECB(4,118)),new ECBlocks(28,new ECB(6,45),new ECB(14,46)),new ECBlocks(30,new ECB(11,24),new ECB(16,25)),new ECBlocks(30,new ECB(30,16),new ECB(2,17))),new Version(25,[6,32,58,84,110],new ECBlocks(26,new ECB(8,106),new ECB(4,107)),new ECBlocks(28,new ECB(8,47),new ECB(13,48)),new ECBlocks(30,new ECB(7,24),new ECB(22,25)),new ECBlocks(30,new ECB(22,15),new ECB(13,16))),new Version(26,[6,30,58,86,114],new ECBlocks(28,new ECB(10,114),new ECB(2,115)),new ECBlocks(28,new ECB(19,46),new ECB(4,47)),new ECBlocks(28,new ECB(28,22),new ECB(6,23)),new ECBlocks(30,new ECB(33,16),new ECB(4,17))),new Version(27,[6,34,62,90,118],new ECBlocks(30,new ECB(8,122),new ECB(4,123)),new ECBlocks(28,new ECB(22,45),new ECB(3,46)),new ECBlocks(30,new ECB(8,23),new ECB(26,24)),new ECBlocks(30,new ECB(12,15),new ECB(28,16))),new Version(28,[6,26,50,74,98,122],new ECBlocks(30,new ECB(3,117),new ECB(10,118)),new ECBlocks(28,new ECB(3,45),new ECB(23,46)),new ECBlocks(30,new ECB(4,24),new ECB(31,25)),new ECBlocks(30,new ECB(11,15),new ECB(31,16))),new Version(29,[6,30,54,78,102,126],new ECBlocks(30,new ECB(7,116),new ECB(7,117)),new ECBlocks(28,new ECB(21,45),new ECB(7,46)),new ECBlocks(30,new ECB(1,23),new ECB(37,24)),new ECBlocks(30,new ECB(19,15),new ECB(26,16))),new Version(30,[6,26,52,78,104,130],new ECBlocks(30,new ECB(5,115),new ECB(10,116)),new ECBlocks(28,new ECB(19,47),new ECB(10,48)),new ECBlocks(30,new ECB(15,24),new ECB(25,25)),new ECBlocks(30,new ECB(23,15),new ECB(25,16))),new Version(31,[6,30,56,82,108,134],new ECBlocks(30,new ECB(13,115),new ECB(3,116)),new ECBlocks(28,new ECB(2,46),new ECB(29,47)),new ECBlocks(30,new ECB(42,24),new ECB(1,25)),new ECBlocks(30,new ECB(23,15),new ECB(28,16))),new Version(32,[6,34,60,86,112,138],new ECBlocks(30,new ECB(17,115)),new ECBlocks(28,new ECB(10,46),new ECB(23,47)),new ECBlocks(30,new ECB(10,24),new ECB(35,25)),new ECBlocks(30,new ECB(19,15),new ECB(35,16))),new Version(33,[6,30,58,86,114,142],new ECBlocks(30,new ECB(17,115),new ECB(1,116)),new ECBlocks(28,new ECB(14,46),new ECB(21,47)),new ECBlocks(30,new ECB(29,24),new ECB(19,25)),new ECBlocks(30,new ECB(11,15),new ECB(46,16))),new Version(34,[6,34,62,90,118,146],new ECBlocks(30,new ECB(13,115),new ECB(6,116)),new ECBlocks(28,new ECB(14,46),new ECB(23,47)),new ECBlocks(30,new ECB(44,24),new ECB(7,25)),new ECBlocks(30,new ECB(59,16),new ECB(1,17))),new Version(35,[6,30,54,78,102,126,150],new ECBlocks(30,new ECB(12,121),new ECB(7,122)),new ECBlocks(28,new ECB(12,47),new ECB(26,48)),new ECBlocks(30,new ECB(39,24),new ECB(14,25)),new ECBlocks(30,new ECB(22,15),new ECB(41,16))),new Version(36,[6,24,50,76,102,128,154],new ECBlocks(30,new ECB(6,121),new ECB(14,122)),new ECBlocks(28,new ECB(6,47),new ECB(34,48)),new ECBlocks(30,new ECB(46,24),new ECB(10,25)),new ECBlocks(30,new ECB(2,15),new ECB(64,16))),new Version(37,[6,28,54,80,106,132,158],new ECBlocks(30,new ECB(17,122),new ECB(4,123)),new ECBlocks(28,new ECB(29,46),new ECB(14,47)),new ECBlocks(30,new ECB(49,24),new ECB(10,25)),new ECBlocks(30,new ECB(24,15),new ECB(46,16))),new Version(38,[6,32,58,84,110,136,162],new ECBlocks(30,new ECB(4,122),new ECB(18,123)),new ECBlocks(28,new ECB(13,46),new ECB(32,47)),new ECBlocks(30,new ECB(48,24),new ECB(14,25)),new ECBlocks(30,new ECB(42,15),new ECB(32,16))),new Version(39,[6,26,54,82,110,138,166],new ECBlocks(30,new ECB(20,117),new ECB(4,118)),new ECBlocks(28,new ECB(40,47),new ECB(7,48)),new ECBlocks(30,new ECB(43,24),new ECB(22,25)),new ECBlocks(30,new ECB(10,15),new ECB(67,16))),new Version(40,[6,30,58,86,114,142,170],new ECBlocks(30,new ECB(19,118),new ECB(6,119)),new ECBlocks(28,new ECB(18,47),new ECB(31,48)),new ECBlocks(30,new ECB(34,24),new ECB(34,25)),new ECBlocks(30,new ECB(20,15),new ECB(61,16)))];function decodeVersion(t,e){let n=32;let s=0;const{length:o}=E;for(let r=0;r<o;r++){const o=E[r];if(t===o||e===o)return m[r+6];let i=hammingWeight(t^o);if(i<n){n=i;s=r+7}if(t!==e){i=hammingWeight(e^o);if(i<n){n=i;s=r+7}}}if(n<=3&&s>=7)return m[s-1];throw new Error("unable to decode version")}function buildFunctionPattern({size:t,version:e,alignmentPatterns:n}){const{length:s}=n;const o=new BitMatrix(t);const r=s-1;o.setRegion(0,0,9,9);o.setRegion(t-8,0,8,9);o.setRegion(0,t-8,9,8);for(let t=0;t<s;t++){const e=n[t]-2;for(let i=0;i<s;i++)t===0&&(i===0||i===r)||t===r&&i===0||o.setRegion(n[i]-2,e,5,5)}o.setRegion(6,9,1,t-17);o.setRegion(9,6,t-17,1);if(e>6){o.setRegion(t-11,0,3,6);o.setRegion(0,t-11,6,3)}return o}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function copyBit(t,e,n,s){return t.get(e,n)?s<<1|1:s<<1}class BitMatrixParser{#M;#S;constructor(t){const{width:e,height:n}=t;this.#S=t.clone();this.#M=Math.min(e,n)}readVersion(){const t=this.#M;const e=toInt32((t-17)/4);if(e<1)throw new Error("illegal version");if(e<=6)return m[e-1];let n=0;let s=0;const o=t-11;const r=this.#S;for(let e=5;e>=0;e--)for(let s=t-9;s>=o;s--)n=copyBit(r,s,e,n);for(let e=5;e>=0;e--)for(let n=t-9;n>=o;n--)s=copyBit(r,e,n,s);const i=decodeVersion(n,s);if(i.size>t)throw new Error("matrix size too small for version");return i}readFormatInfo(){let t=0;let e=0;const n=this.#S;const s=this.#M;const o=s-7;for(let e=0;e<=8;e++)e!==6&&(t=copyBit(n,e,8,t));for(let e=7;e>=0;e--)e!==6&&(t=copyBit(n,8,e,t));for(let t=s-1;t>=o;t--)e=copyBit(n,8,t,e);for(let t=s-8;t<s;t++)e=copyBit(n,t,8,e);return decodeFormatInfo(t,e)}readCodewords(t,e){let n=0;let s=0;let o=0;let r=true;const i=this.#M;const c=this.#S;const a=t.getECBlocks(e);const l=buildFunctionPattern(t);const u=new Uint8Array(a.numTotalCodewords);for(let t=i-1;t>0;t-=2){t===6&&t--;for(let e=0;e<i;e++){const a=r?i-1-e:e;for(let e=0;e<2;e++){const r=t-e;if(!l.get(r,a)){n++;o<<=1;c.get(r,a)&&(o|=1);if(n===8){u[s++]=o;n=0;o=0}}}}r=!r}if(s!==a.numTotalCodewords)throw new Error("illegal codewords length");return u}unmask(t){const e=this.#M;const n=this.#S;for(let s=0;s<e;s++)for(let o=0;o<e;o++)isApplyMask(t,o,s)&&n.flip(o,s)}remask(t){this.unmask(t)}mirror(){const t=this.#M;const e=this.#S;for(let n=0;n<t;n++)for(let s=n+1;s<t;s++)if(e.get(n,s)!==e.get(s,n)){e.flip(n,s);e.flip(s,n)}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class DataBlock{#z;#C;constructor(t,e){this.#z=t;this.#C=e}get codewords(){return this.#z}get numDataCodewords(){return this.#C}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Polynomial{#A;#x;constructor(t,e){const{length:n}=e;if(n<=0)throw new Error("polynomial coefficients cannot empty");this.#A=t;if(n>1&&e[0]===0){let t=1;while(t<n&&e[t]===0)t++;if(t===n)this.#x=new Int32Array([0]);else{const s=new Int32Array(n-t);s.set(e.subarray(t));this.#x=s}}else this.#x=e}get coefficients(){return this.#x}isZero(){return this.#x[0]===0}getDegree(){return this.#x.length-1}getCoefficient(t){const e=this.#x;return e[e.length-1-t]}evaluate(t){if(t===0)return this.getCoefficient(0);let e;const n=this.#x;if(t===1){e=0;for(const t of n)e^=t;return e}[e]=n;const s=this.#A;const{length:o}=n;for(let r=1;r<o;r++)e=s.multiply(t,e)^n[r];return e}multiply(t){const e=this.#A;const n=this.#x;const{length:s}=n;if(t instanceof Polynomial){if(this.isZero()||t.isZero())return e.zero;const o=t.#x;const r=o.length;const i=new Int32Array(s+r-1);for(let t=0;t<s;t++){const s=n[t];for(let n=0;n<r;n++)i[t+n]^=e.multiply(s,o[n])}return new Polynomial(e,i)}if(t===0)return e.zero;if(t===1)return this;const o=new Int32Array(s);for(let r=0;r<s;r++)o[r]=e.multiply(n[r],t);return new Polynomial(e,o)}multiplyByMonomial(t,e){const n=this.#A;if(e===0)return n.zero;const s=this.#x;const{length:o}=s;const r=new Int32Array(o+t);for(let t=0;t<o;t++)r[t]=n.multiply(s[t],e);return new Polynomial(n,r)}addOrSubtract(t){if(this.isZero())return t;if(t.isZero())return this;let e=t.#x;let n=e.length;let s=this.#x;let o=s.length;if(n<o){[n,o]=[o,n];[e,s]=[s,e]}const r=n-o;const i=new Int32Array(n);i.set(e.subarray(0,r));for(let t=r;t<n;t++)i[t]=s[t-r]^e[t];return new Polynomial(this.#A,i)}divide(t){const e=this.#A;let n=e.zero;let s=this;const o=t.getCoefficient(t.getDegree());const r=e.invert(o);while(s.getDegree()>=t.getDegree()&&!s.isZero()){const o=s.getDegree();const i=o-t.getDegree();const c=e.multiply(s.getCoefficient(o),r);const a=t.multiplyByMonomial(i,c);const l=e.buildPolynomial(i,c);n=n.addOrSubtract(l);s=s.addOrSubtract(a)}return[n,s]}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class GaloisField{#M;#T;#v;#R;#D;#F;constructor(t,e,n){let s=1;const o=new Int32Array(e);for(let n=0;n<e;n++){o[n]=s;s*=2;if(s>=e){s^=t;s&=e-1}}const r=new Int32Array(e);for(let t=0,n=e-1;t<n;t++)r[o[t]]=t;this.#M=e;this.#D=o;this.#F=r;this.#R=n;this.#T=new Polynomial(this,new Int32Array([1]));this.#v=new Polynomial(this,new Int32Array([0]))}get size(){return this.#M}get one(){return this.#T}get zero(){return this.#v}get generator(){return this.#R}exp(t){return this.#D[t]}log(t){return this.#F[t]}invert(t){return this.#D[this.#M-this.#F[t]-1]}multiply(t,e){if(t===0||e===0)return 0;const n=this.#F;return this.#D[(n[t]+n[e])%(this.#M-1)]}buildPolynomial(t,e){if(e===0)return this.#v;const n=new Int32Array(t+1);n[0]=e;return new Polynomial(this,n)}}const p=new GaloisField(285,256,0);
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function runEuclideanAlgorithm(t,e,n,s){e.getDegree()<n.getDegree()&&([e,n]=[n,e]);let o=n;let r=t.one;let i=e;let c=t.zero;while(2*o.getDegree()>=s){let e=c;let n=i;c=r;i=o;if(i.isZero())throw new Error("remainder last was zero");o=n;let s=t.zero;let a=o.getDegree();const l=i.getDegree();const u=i.getCoefficient(l);const w=t.invert(u);while(a>=l&&!o.isZero()){const e=o.getDegree()-l;const n=t.multiply(o.getCoefficient(a),w);s=s.addOrSubtract(t.buildPolynomial(e,n));o=o.addOrSubtract(i.multiplyByMonomial(e,n));a=o.getDegree()}r=s.multiply(c).addOrSubtract(e);if(a>=l)throw new Error("division algorithm failed to reduce polynomial")}const a=r.getCoefficient(0);if(a===0)throw new Error("sigma tilde(0) was zero");const l=t.invert(a);const u=r.multiply(l);const w=o.multiply(l);return[u,w]}function findErrorLocations(t,e){const n=e.getDegree();if(n===1)return new Int32Array([e.getCoefficient(1)]);let s=0;const{size:o}=t;const r=new Int32Array(n);for(let i=1;i<o&&s<n;i++)e.evaluate(i)===0&&(r[s++]=t.invert(i));if(s!==n)throw new Error("error locator degree does not match number of roots");return r}function findErrorMagnitudes(t,e,n){const{length:s}=n;const o=new Int32Array(s);for(let r=0;r<s;r++){let i=1;const c=t.invert(n[r]);for(let e=0;e<s;e++)if(r!==e){const s=t.multiply(n[e],c);const o=(s&1)===0?s|1:s&-2;i=t.multiply(i,o)}o[r]=t.multiply(e.evaluate(c),t.invert(i));t.generator!==0&&(o[r]=t.multiply(o[r],c))}return o}let k=class Decoder{#A;constructor(t=p){this.#A=t}decode(t,e){let n=true;const s=this.#A;const{generator:o}=s;const r=new Polynomial(s,t);const i=new Int32Array(e);for(let t=0;t<e;t++){const c=r.evaluate(s.exp(t+o));i[e-1-t]=c;c!==0&&(n=false)}if(!n){const n=new Polynomial(s,i);const[o,r]=runEuclideanAlgorithm(s,s.buildPolynomial(e,1),n,e);const c=findErrorLocations(s,o);const a=findErrorMagnitudes(s,r,c);const l=c.length;const u=t.length;for(let e=0;e<l;e++){const n=u-1-s.log(c[e]);if(n<0)throw new Error("bad error location");t[n]=t[n]^a[e]}return l}return 0}};
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function correctErrors(t,e){const n=new Int32Array(t);const s=t.length-e;const o=(new k).decode(n,s);return[n,o]}function getDataBlocks(t,e,n){const{ecBlocks:s,numTotalCodewords:o,numECCodewordsPerBlock:r}=e.getECBlocks(n);if(t.length!==o)throw new Error("failed to get data blocks");const i=[];for(const{count:t,numDataCodewords:e}of s)for(let n=0;n<t;n++){const t=r+e;i.push(new DataBlock(new Uint8Array(t),e))}const{length:c}=i;let a=c-1;const l=i[0].codewords.length;while(a>=0){const t=i[a].codewords.length;if(t===l)break;a--}a++;let u=0;const w=l-r;for(let e=0;e<w;e++)for(let n=0;n<c;n++)i[n].codewords[e]=t[u++];for(let e=a;e<c;e++)i[e].codewords[w]=t[u++];const h=i[0].codewords.length;for(let e=w;e<h;e++)for(let n=0;n<c;n++){const s=n<a?e:e+1;i[n].codewords[s]=t[u++]}return i}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getUnicodeCodes(t,e){const n=[];for(const s of t){const t=s.codePointAt(0);n.push(t==null||t>e?63:t)}return new Uint8Array(n)}function encode$1(t,e){switch(e){case Charset.ASCII:return getUnicodeCodes(t,127);case Charset.ISO_8859_1:return getUnicodeCodes(t,255);case Charset.UTF_8:return(new TextEncoder).encode(t);default:throw Error(`built-in encode not support charset: ${e.label}`)}}function decode(t,e){try{return new TextDecoder(e.label).decode(t)}catch{throw Error(`built-in decode not support charset: ${e.label}`)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function parse(t,e,{mask:n,level:s}){let o=0;let r=0;t.unmask(n);const i=e.getECBlocks(s);const c=t.readCodewords(e,s);const a=getDataBlocks(c,e,s);const l=new Uint8Array(i.numTotalDataCodewords);for(const{codewords:t,numDataCodewords:e}of a){const[n,s]=correctErrors(t,e);l.set(n.subarray(0,e),o);r+=s;o+=e}return[l,r]}class Decoder{#N;
/**
   * @constructor
   * @param options The options of decoder.
   */
constructor({decode:t=decode}={}){this.#N=t}
/**
   * @method decode
   * @description Decode the qrcode matrix.
   * @param matrix The qrcode matrix.
   */decode(t){let e=0;let n=false;let s;let o;let r;const i=new BitMatrixParser(t);try{s=i.readVersion();r=i.readFormatInfo();[o,e]=parse(i,s,r)}catch{r!=null&&i.remask(r.mask);i.mirror();n=true;s=i.readVersion();r=i.readFormatInfo();[o,e]=parse(i,s,r)}return new Decoded(decode$1(o,s,this.#N),s,r,e,n)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const b=.75;function offset(t){return toInt32(t/32)}function makeArray(t){return new Int32Array(Math.ceil(t/32))}class BitArray{#O;#w;constructor(t=0){this.#O=t;this.#w=makeArray(t)}#V(t){const e=this.#w;if(t>e.length*32){const n=makeArray(Math.ceil(t/b));n.set(e);this.#w=n}this.#O=t}get length(){return this.#O}get byteLength(){return Math.ceil(this.#O/8)}set(t){this.#w[offset(t)]|=getBitMask(t)}get(t){return toBit(this.#w[offset(t)]>>>getBitOffset(t))}xor(t){const e=this.#w;const n=t.#w;const s=Math.min(this.#O,t.#O);for(let t=0;t<s;t++)e[t]^=n[t]}append(t,e=1){let n=this.#O;if(t instanceof BitArray){e=t.#O;this.#V(n+e);for(let s=0;s<e;s++){t.get(s)!==0&&this.set(n);n++}}else{this.#V(n+e);for(let s=e-1;s>=0;s--){toBit(t>>>s)!==0&&this.set(n);n++}}}writeToUint8Array(t,e,n,s){for(let o=0;o<s;o++){let s=0;for(let e=0;e<8;e++)this.get(t++)!==0&&(s|=1<<7-e);e[n+o]=s}}clear(){this.#w.fill(0)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class ByteMatrix{#M;#a;constructor(t){this.#M=t;this.#a=new Int8Array(t*t)}get size(){return this.#M}set(t,e,n){this.#a[e*this.#M+t]=n}get(t,e){return this.#a[e*this.#M+t]}clear(t){this.#a.fill(t)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const y=1335;const P=21522;const M=7973;const I=[[1,1,1,1,1,1,1],[1,0,0,0,0,0,1],[1,0,1,1,1,0,1],[1,0,1,1,1,0,1],[1,0,1,1,1,0,1],[1,0,0,0,0,0,1],[1,1,1,1,1,1,1]];const S=[[1,1,1,1,1],[1,0,0,0,1],[1,0,1,0,1],[1,0,0,0,1],[1,1,1,1,1]];const z=[[8,0],[8,1],[8,2],[8,3],[8,4],[8,5],[8,7],[8,8],[7,8],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8]];function isEmpty(t,e,n){return t.get(e,n)===-1}function embedFinderPattern(t,e,n){for(let s=0;s<7;s++){const o=I[s];for(let r=0;r<7;r++)t.set(e+r,n+s,o[r])}}function embedHorizontalSeparator(t,e,n){for(let s=0;s<8;s++)t.set(e+s,n,0)}function embedVerticalSeparator(t,e,n){for(let s=0;s<7;s++)t.set(e,n+s,0)}function embedFinderPatternsAndSeparators(t){const e=7;const n=8;const s=7;const{size:o}=t;embedFinderPattern(t,0,0);embedFinderPattern(t,o-e,0);embedFinderPattern(t,0,o-e);embedHorizontalSeparator(t,0,n-1);embedHorizontalSeparator(t,o-n,n-1);embedHorizontalSeparator(t,0,o-n);embedVerticalSeparator(t,s,0);embedVerticalSeparator(t,o-s-1,0);embedVerticalSeparator(t,s,o-s)}function embedTimingPatterns(t){const e=t.size-8;for(let n=8;n<e;n++){const e=n+1&1;isEmpty(t,n,6)&&t.set(n,6,e)}for(let n=8;n<e;n++){const e=n+1&1;isEmpty(t,6,n)&&t.set(6,n,e)}}function embedAlignmentPattern(t,e,n){for(let s=0;s<5;s++){const o=S[s];for(let r=0;r<5;r++)t.set(e+r,n+s,o[r])}}function embedAlignmentPatterns(t,{version:e}){if(e>=2){const{alignmentPatterns:n}=m[e-1];const{length:s}=n;for(let e=0;e<s;e++){const o=n[e];for(let e=0;e<s;e++){const s=n[e];isEmpty(t,s,o)&&embedAlignmentPattern(t,s-2,o-2)}}}}function embedDarkModule(t){t.set(8,t.size-8,1)}function makeFormatInfoBits(t,e,n){const s=e.bits<<3|n;t.append(s,5);const o=calculateBCHCode(s,y);t.append(o,10);const r=new BitArray;r.append(P,15);t.xor(r)}function embedFormatInfo(t,e,n){const s=new BitArray;makeFormatInfoBits(s,e,n);const{size:o}=t;const{length:r}=s;for(let e=0;e<r;e++){const[n,i]=z[e];const c=s.get(r-1-e);t.set(n,i,c);e<8?t.set(o-e-1,8,c):t.set(8,o-7+(e-8),c)}embedDarkModule(t)}function makeVersionInfoBits(t,e){t.append(e,6);const n=calculateBCHCode(e,M);t.append(n,12)}function embedVersionInfo(t,{version:e}){if(e>=7){const n=new BitArray;makeVersionInfoBits(n,e);let s=17;const{size:o}=t;for(let e=0;e<6;e++)for(let r=0;r<3;r++){const i=n.get(s--);t.set(e,o-11+r,i);t.set(o-11+r,e,i)}}}function embedCodewords(t,e,n){let s=0;const{size:o}=t;const{length:r}=e;for(let i=o-1;i>=1;i-=2){i===6&&(i=5);for(let c=0;c<o;c++)for(let a=0;a<2;a++){const l=i-a;const u=(i+1&2)===0;const w=u?o-1-c:c;if(isEmpty(t,l,w)){let o=0;s<r&&(o=e.get(s++));isApplyMask(n,l,w)&&(o^=1);t.set(l,w,o)}}}}function embedFunctionPatterns(t,e){embedFinderPatternsAndSeparators(t);embedAlignmentPatterns(t,e);embedTimingPatterns(t)}function embedEncodingRegion(t,e,n,s,o){embedFormatInfo(t,s,o);embedVersionInfo(t,n);embedCodewords(t,e,o)}function buildMatrix(t,e,n,s){const o=new ByteMatrix(e.size);o.clear(-1);embedFunctionPatterns(o,e);embedEncodingRegion(o,t,e,n,s);return o}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class BlockPair{#L;#_;constructor(t,e){this.#L=e;this.#_=t}get ecCodewords(){return this.#L}get dataCodewords(){return this.#_}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function buildGenerator(t,e,n){const{length:s}=e;if(n>=s){const{generator:o}=t;let r=e[s-1];for(let i=s;i<=n;i++){const n=new Int32Array([1,t.exp(i-1+o)]);const s=r.multiply(new Polynomial(t,n));e.push(s);r=s}}return e[n]}let A=class Encoder{#A;#G;constructor(t=p){this.#A=t;this.#G=[new Polynomial(t,new Int32Array([1]))]}encode(t,e){const n=t.length-e;const s=new Int32Array(n);const o=buildGenerator(this.#A,this.#G,e);s.set(t.subarray(0,n));const r=new Polynomial(this.#A,s);const i=r.multiplyByMonomial(e,1);const[,c]=i.divide(o);const{coefficients:a}=c;const l=e-a.length;const u=n+l;t.fill(0,n,u);t.set(a,u)}};
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function generateECCodewords(t,e){const n=t.length;const s=new Int32Array(n+e);s.set(t);(new A).encode(s,e);return new Uint8Array(s.subarray(n))}function injectECCodewords(t,{ecBlocks:e,numECCodewordsPerBlock:n}){let s=0;let o=0;let r=0;const i=[];for(const{count:c,numDataCodewords:a}of e)for(let e=0;e<c;e++){const e=new Uint8Array(a);t.writeToUint8Array(r*8,e,0,a);const c=generateECCodewords(e,n);i.push(new BlockPair(e,c));r+=a;s=Math.max(s,c.length);o=Math.max(o,a)}const c=new BitArray;for(let t=0;t<o;t++)for(const{dataCodewords:e}of i)t<e.length&&c.append(e[t],8);for(let t=0;t<s;t++)for(const{ecCodewords:e}of i)t<e.length&&c.append(e[t],8);return c}function appendTerminator(t,e){const n=e*8;for(let e=0;e<4&&t.length<n;e++)t.append(0);const s=t.length&7;if(s>0)for(let e=s;e<8;e++)t.append(0);const o=e-t.byteLength;for(let e=0;e<o;e++)t.append(e&1?17:236,8)}function isByteMode(t){return t.mode===Mode.BYTE}function isHanziMode(t){return t.mode===Mode.HANZI}function appendModeInfo(t,e){t.append(e.bits,4)}function appendECI(t,e,n){if(isByteMode(e)){const[s]=e.charset.values;if(s!==n){t.append(Mode.ECI.bits,4);s<=127?t.append(s,8):s<=16383?t.append(32768|s,16):t.append(12582912|s,24);return s}}return n}function appendFNC1Info(t,e){const[n,s]=e;switch(n){case"GS1":appendModeInfo(t,Mode.FNC1_FIRST_POSITION);break;case"AIM":appendModeInfo(t,Mode.FNC1_SECOND_POSITION);t.append(s,8);break}}function getSegmentLength(t,e){return isByteMode(t)?e.byteLength:t.content.length}function appendLengthInfo(t,e,n,s){t.append(s,e.getCharacterCountBits(n))}function willFit(t,e,n){const s=e.getECBlocks(n);const o=Math.ceil(t/8);return s.numTotalDataCodewords>=o}function chooseVersion(t,e){for(const n of m)if(willFit(t,n,e))return n;throw new Error("data too big for all versions")}function calculateBitsNeeded(t,e){let n=0;for(const{mode:s,head:o,body:r}of t)n+=o.length+s.getCharacterCountBits(e)+r.length;return n}function chooseRecommendVersion(t,e){const n=calculateBitsNeeded(t,m[0]);const s=chooseVersion(n,e);const o=calculateBitsNeeded(t,s);return chooseVersion(o,e)}function chooseBestMaskAndMatrix(t,e,n){let s=0;let o=buildMatrix(t,e,n,s);let r=calculateMaskPenalty(o);for(let i=1;i<8;i++){const c=buildMatrix(t,e,n,i);const a=calculateMaskPenalty(c);if(a<r){s=i;o=c;r=a}}return[s,o]}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const x=4095;class Dict{#U;#H;#w;#q;#M;#W;#$;constructor(t){const e=1<<t;const n=e+1;this.#U=e;this.#H=n;this.#q=t;this.reset()}get bof(){return this.#U}get eof(){return this.#H}get bits(){return this.#w}get depth(){return this.#q}reset(){const t=this.#q+1;this.#w=t;this.#M=1<<t;this.#$=new Map;this.#W=this.#H+1}add(t,e){let n=this.#W;if(n>x)return false;this.#$.set(t<<8|e,n++);let s=this.#w;let o=this.#M;n>o&&(o=1<<++s);this.#w=s;this.#M=o;this.#W=n;return true}get(t,e){return this.#$.get(t<<8|e)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class DictStream{#w=0;#j;#Z=0;#a=[];constructor(t){this.#j=t}write(t){let e=this.#w;let n=this.#Z|t<<e;e+=this.#j.bits;const s=this.#a;while(e>=8){s.push(n&255);n>>=8;e-=8}this.#w=e;this.#Z=n}pipe(t){const e=this.#a;this.#w>0&&e.push(this.#Z);t.writeByte(this.#j.depth);const{length:n}=e;for(let s=0;s<n;){const o=n-s;if(o>=255){t.writeByte(255);t.writeBytes(e,s,255);s+=255}else{t.writeByte(o);t.writeBytes(e,s,o);s=n}}t.writeByte(0)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function compress(t,e,n){const s=new Dict(e);const o=new DictStream(s);o.write(s.bof);if(t.length>0){let e=t[0];const{length:n}=t;for(let r=1;r<n;r++){const n=t[r];const i=s.get(e,n);if(i!=null)e=i;else{o.write(e);if(!s.add(e,n)){o.write(s.bof);s.reset()}e=n}}o.write(e)}o.write(s.eof);o.pipe(n)}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class ByteStream{#a=[];get bytes(){return this.#a}writeByte(t){this.#a.push(t&255)}writeInt16(t){this.#a.push(t&255,t>>8&255)}writeBytes(t,e=0,n=t.length){const s=this.#a;for(let o=0;o<n;o++)s.push(t[e+o]&255)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const{fromCharCode:T}=String;function encode(t){t&=63;if(t>=0){if(t<26)return 65+t;if(t<52)return t-26+97;if(t<62)return t-52+48;if(t===62)return 43;if(t===63)return 47}throw new Error(`illegal char: ${T(t)}`)}class Base64Stream{#w=0;#Z=0;#O=0;#K=new ByteStream;get bytes(){return this.#K.bytes}write(t){let e=this.#w+8;const n=this.#K;const s=this.#Z<<8|t&255;while(e>=6){n.writeByte(encode(s>>>e-6));e-=6}this.#O++;this.#w=e;this.#Z=s}close(){const t=this.#w;const e=this.#K;if(t>0){e.writeByte(encode(this.#Z<<6-t));this.#w=0;this.#Z=0}const n=this.#O;if(n%3!=0){const t=3-n%3;for(let n=0;n<t;n++)e.writeByte(61)}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class GIFImage{#k;#b;#Q;#Y;#J=[];constructor(t,e,{foreground:n=[0,0,0],background:s=[255,255,255]}={}){this.#k=t;this.#b=e;this.#Q=n;this.#Y=s}#X(){const t=this.#k;const e=this.#b;const n=new ByteStream;const s=this.#Y;const o=this.#Q;n.writeBytes([71,73,70,56,57,97]);n.writeInt16(t);n.writeInt16(e);n.writeBytes([128,0,0]);n.writeBytes([s[0],s[1],s[2]]);n.writeBytes([o[0],o[1],o[2]]);n.writeByte(44);n.writeInt16(0);n.writeInt16(0);n.writeInt16(t);n.writeInt16(e);n.writeByte(0);compress(this.#J,2,n);n.writeByte(59);return n.bytes}set(t,e,n){this.#J[e*this.#k+t]=n}toDataURL(){const t=this.#X();const e=new Base64Stream;for(const n of t)e.write(n);e.close();const n=e.bytes;let s="data:image/gif;base64,";for(const t of n)s+=T(t);return s}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Encoded{#n;#s;#r;#S;constructor(t,e,n,s){this.#n=s;this.#s=n;this.#S=t;this.#r=e}get size(){return this.#S.size}get mask(){return this.#n}get level(){return this.#s.name}get version(){return this.#r.version}get(t,e){const{size:n}=this.#S;if(t<0||e<0||t>=n||e>=n)throw new Error(`illegal coordinate: [${t}, ${e}]`);return this.#S.get(t,e)}
/**
   * @method toDataURL
   * @param moduleSize The size of one qrcode module
   * @param options Set rest options of gif, like margin, foreground and background.
   */toDataURL(t=2,{margin:e=t*4,...n}={}){t=Math.max(1,t|0);e=Math.max(0,e|0);const s=this.#S;const o=s.size;const r=t*o+e*2;const i=new GIFImage(r,r,n);const c=r-e;for(let n=0;n<r;n++)for(let o=0;o<r;o++)if(o>=e&&o<c&&n>=e&&n<c){const r=toInt32((o-e)/t);const c=toInt32((n-e)/t);i.set(o,n,s.get(r,c))}else i.set(o,n,0);return i.toDataURL()}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function assertContent(t){if(t==="")throw new Error("segment content should be at least 1 character")}function assertCharset(t){if(!(t instanceof Charset))throw new Error("illegal charset")}function assertHints(t){const{fnc1:e}=t;if(e!=null){const[t]=e;if(t!=="GS1"&&t!=="AIM")throw new Error("illegal fn1 hint");if(t==="AIM"){const[,t]=e;if(t<0||t>255||!Number.isInteger(t))throw new Error("illegal fn1 application indicator")}}}function assertLevel(t){if(["L","M","Q","H"].indexOf(t)<0)throw new Error("illegal error correction level")}function assertVersion(t){if(t!=="Auto"&&(t<1||t>40||!Number.isInteger(t)))throw new Error("illegal version")}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Encoder{#tt;#s;#X;#r;
/**
   * @constructor
   * @param options The options of encoder.
   */
constructor({hints:t={},level:e="L",version:n="Auto",encode:s=encode$1}={}){assertHints(t);assertLevel(e);assertVersion(n);this.#tt=t;this.#X=s;this.#r=n;this.#s=ECLevel[e]}
/**
   * @method encode
   * @description Encode the segments.
   * @param segments The segments.
   */encode(...t){const e=this.#s;const n=this.#X;const{fnc1:s}=this.#tt;const o=this.#r;const r=[];let i=false;let[c]=Charset.ISO_8859_1.values;for(const e of t){const{mode:t}=e;const o=new BitArray;const a=e.encode(n);const l=getSegmentLength(e,a);c=appendECI(o,e,c);if(s!=null&&!i){i=true;appendFNC1Info(o,s)}appendModeInfo(o,t);isHanziMode(e)&&o.append(1,4);r.push({mode:t,head:o,body:a,length:l})}let a;if(o==="Auto")a=chooseRecommendVersion(r,e);else{a=m[o-1];const t=calculateBitsNeeded(r,a);if(!willFit(t,a,e))throw new Error("data too big for requested version")}const l=new BitArray;for(const{mode:t,head:e,body:n,length:s}of r){l.append(e);appendLengthInfo(l,t,a,s);l.append(n)}const u=a.getECBlocks(e);appendTerminator(l,u.numTotalDataCodewords);const w=injectECCodewords(l,u);const[h,f]=chooseBestMaskAndMatrix(w,a,e);return new Encoded(f,a,e,h)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Byte{#et;#nt;
/**
   * @constructor
   * @param content The content to encode.
   * @param charset The charset of the content.
   */
constructor(t,e=Charset.ISO_8859_1){assertContent(t);assertCharset(e);this.#et=t;this.#nt=e}get mode(){return Mode.BYTE}get content(){return this.#et}get charset(){return this.#nt}
/**
   * @method encode
   * @description Encode the segment.
   * @param encode The text encode function.
   */encode(t){const e=new BitArray;const n=t(this.#et,this.#nt);for(const t of n)e.append(t,8);return e}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Point{#st;#ot;constructor(t,e){this.#st=t;this.#ot=e}get x(){return this.#st}get y(){return this.#ot}}function distance(t,e){return Math.sqrt(squaredDistance(t,e))}function squaredDistance(t,e){const n=t.x-e.x;const s=t.y-e.y;return n*n+s*s}function calculateTriangleArea(t,e,n){const{x:s,y:o}=t;const{x:r,y:i}=e;const{x:c,y:a}=n;return Math.abs(s*(i-a)+r*(a-o)+c*(o-i))/2}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function calculateIntersectRatio({ratios:t}){return t[toInt32(t.length/2)]/2}class Pattern extends Point{#rt;#k;#b;#it;#ct;#at=1;#lt;#ut;static noise(t){return t.#rt}static width(t){return t.#k}static height(t){return t.#b}static combined(t){return t.#at}static rect(t){return t.#it}static equals(t,e,n,s,o){const{modules:r}=t.#lt;const i=t.#ut;if(Math.abs(e-t.x)<=i&&Math.abs(n-t.y)<=i){const e=t.#ct;const n=(s+o)/r/2;const i=Math.abs(n-e);if(i<=1||i<=e)return true}return false}static combine(t,e,n,s,o,r){const i=t.#at;const c=i+1;const a=(t.x*i+e)/c;const l=(t.y*i+n)/c;const u=(t.#rt*i+r)/c;const w=(t.#k*i+s)/c;const h=(t.#b*i+o)/c;const f=new Pattern(t.#lt,a,l,w,h,u);f.#at=c;return f}constructor(t,e,n,s,o,r){super(e,n);const{modules:i}=t;const c=s/2;const a=o/2;const l=s/i;const u=o/i;const w=l/2;const h=u/2;const f=calculateIntersectRatio(t);const d=(l+u)/2;this.#rt=r;this.#k=s;this.#b=o;this.#lt=t;this.#ct=d;this.#it=[e-c+w,n-a+h,e+c-w,n+a-h];this.#ut=d*f}get moduleSize(){return this.#ct}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class GridSampler{#S;#wt;constructor(t,e){this.#S=t;this.#wt=e}sample(t,e){const n=this.#S;const s=n.width;const o=this.#wt;const r=n.height;const i=new BitMatrix(t,e);for(let c=0;c<e;c++)for(let e=0;e<t;e++){const[t,a]=o.mapping(e+.5,c+.5);const l=toInt32(t);const u=toInt32(a);l>=0&&u>=0&&l<s&&u<r&&n.get(l,u)&&i.set(e,c)}return i}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class PlotLine{#ht;#ft;#dt;#Ct;#Bt;#Et;constructor(t,e){let n=toInt32(e.x);let s=toInt32(e.y);let o=toInt32(t.x);let r=toInt32(t.y);const i=Math.abs(s-r)>Math.abs(n-o);i&&([o,r,n,s]=[r,o,s,n]);const c=o<n?1:-1;this.#Ct=i;this.#dt=n+c;this.#ht=new Point(n,s);this.#ft=new Point(o,r);this.#Bt=[c,r<s?1:-1];this.#Et=[Math.abs(n-o),Math.abs(s-r)]}*points(){const t=this.#dt;const e=this.#Ct;const{y:n}=this.#ht;const[s,o]=this.#Bt;const[r,i]=this.#Et;const{x:c,y:a}=this.#ft;let l=toInt32(-r/2);for(let u=c,w=a;u!==t;u+=s){yield[e?w:u,e?u:w];l+=i;if(l>0){if(w===n)break;w+=o;l-=r}}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function sizeOfBlackWhiteBlackRun(t,e,n){let s=0;const{width:o,height:r}=t;const i=(e.x+n.x)/2;const c=(e.y+n.y)/2;const a=new Point(i,c);const l=new PlotLine(e,a).points();for(const[n,i]of l){if(n<0||i<0||n>=o||i>=r)return s===2?distance(e,new Point(n,i)):NaN;if(s===1===(t.get(n,i)===1)){if(s===2)return distance(e,new Point(n,i));s++}}return NaN}function sizeOfBlackWhiteBlackRunBothWays(t,e,n){const s=sizeOfBlackWhiteBlackRun(t,e,n);if(Number.isNaN(s))return NaN;const{x:o,y:r}=n;const{x:i,y:c}=e;const a=i-(o-i);const l=c-(r-c);const u=sizeOfBlackWhiteBlackRun(t,e,new Point(a,l));return Number.isNaN(u)?NaN:s+u-1}function calculateModuleSizeOneWay(t,e,n){const s=new Point(toInt32(e.x),toInt32(e.y));const o=new Point(toInt32(n.x),toInt32(n.y));const r=sizeOfBlackWhiteBlackRunBothWays(t,s,o);const i=sizeOfBlackWhiteBlackRunBothWays(t,o,s);return Number.isNaN(r)?i/7:Number.isNaN(i)?r/7:(r+i)/14}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function calculateSizeRatio(t,e){return t>e?t/e:e/t}function calculateDistanceRatio(t,e){const n=Math.max(calculateSizeRatio(Pattern.width(t),Pattern.width(e)),calculateSizeRatio(Pattern.height(t),Pattern.height(e)));return n*n}function crossProductZ(t,e,n){const{x:s,y:o}=e;return(n.x-s)*(t.y-o)-(n.y-o)*(t.x-s)}function orderFinderPatterns(t){let e;let n;let s;const[o,r,i]=t;const c=squaredDistance(o,r)*calculateDistanceRatio(o,r);const a=squaredDistance(o,i)*calculateDistanceRatio(o,i);const l=squaredDistance(r,i)*calculateDistanceRatio(r,i);l>=c&&l>=a?[e,s,n]=t:a>=l&&a>=c?[s,e,n]=t:[s,n,e]=t;crossProductZ(s,e,n)<0&&([s,n]=[n,s]);return[e,n,s]}function calculateBottomRightPoint([t,e,n]){const{x:s,y:o}=t;const r=e.x+n.x-s;const i=e.y+n.y-o;return new Point(r,i)}function calculateSymbolSize([t,e,n],s){const o=distance(t,e);const r=distance(t,n);const i=round((o+r)/s/2)+7;switch(i&3){case 0:return i+1;case 2:return i-1;case 3:return Math.min(i+2,B)}return i}class FinderPatternGroup{#gt;#M;#S;#mt;#ct;#pt;#kt;static moduleSizes(t){if(t.#kt==null){const e=t.#S;const[n,s,o]=t.#pt;t.#kt=[calculateModuleSizeOneWay(e,n,s),calculateModuleSizeOneWay(e,n,o)]}return t.#kt}static size(t){if(t.#M==null){const e=FinderPatternGroup.moduleSize(t);t.#M=calculateSymbolSize(t.#pt,e)}return t.#M}static moduleSize(t){t.#ct==null&&(t.#ct=accumulate(FinderPatternGroup.moduleSizes(t))/2);return t.#ct}static contains(t,e){const n=t.#bt();const[s,o,r]=t.#pt;const i=FinderPatternGroup.bottomRight(t);const c=calculateTriangleArea(s,o,e);const a=calculateTriangleArea(o,i,e);const l=calculateTriangleArea(i,r,e);const u=calculateTriangleArea(r,s,e);return c+a+l+u-n<1}static bottomRight(t){t.#mt==null&&(t.#mt=calculateBottomRightPoint(t.#pt));return t.#mt}constructor(t,e){this.#S=t;this.#pt=orderFinderPatterns(e)}get topLeft(){return this.#pt[0]}get topRight(){return this.#pt[1]}get bottomLeft(){return this.#pt[2]}#bt(){const[t,e,n]=this.#pt;const s=FinderPatternGroup.bottomRight(this);if(this.#gt==null){const o=calculateTriangleArea(t,e,s);const r=calculateTriangleArea(s,n,t);this.#gt=o+r}return this.#gt}}function calculateTopLeftAngle({topLeft:t,topRight:e,bottomLeft:n}){const{x:s,y:o}=t;const r=e.x-s;const i=e.y-o;const c=n.x-s;const a=n.y-o;const l=r*c+i*a;const u=(r*r+i*i)*(c*c+a*a);return Math.acos(l/Math.sqrt(u))}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class Detected{#S;#yt;#Pt;#wt;constructor(t,e,n,s){const o=new GridSampler(t,e);const r=FinderPatternGroup.size(n);this.#S=t;this.#wt=e;this.#Pt=n;this.#yt=s;this.#S=o.sample(r,r)}get matrix(){return this.#S}get finder(){return this.#Pt}get alignment(){return this.#yt}get size(){return FinderPatternGroup.size(this.#Pt)}get moduleSize(){return FinderPatternGroup.moduleSize(this.#Pt)}
/**
   * @method mapping
   * @description Get the mapped point.
   * @param x The x of point.
   * @param y The y of point.
   */mapping(t,e){[t,e]=this.#wt.mapping(t,e);return new Point(t,e)}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class PerspectiveTransform{#Mt;#It;#St;#zt;#At;#xt;#Tt;#vt;#Rt;constructor(t,e,n,s,o,r,i,c,a){this.#Mt=t;this.#It=s;this.#St=i;this.#zt=e;this.#At=o;this.#xt=c;this.#Tt=n;this.#vt=r;this.#Rt=a}inverse(){const t=this.#Mt;const e=this.#It;const n=this.#St;const s=this.#zt;const o=this.#At;const r=this.#xt;const i=this.#Tt;const c=this.#vt;const a=this.#Rt;return new PerspectiveTransform(o*a-r*c,r*i-s*a,s*c-o*i,n*c-e*a,t*a-n*i,e*i-t*c,e*r-n*o,n*s-t*r,t*o-e*s)}times(t){const e=this.#Mt;const n=this.#It;const s=this.#St;const o=this.#zt;const r=this.#At;const i=this.#xt;const c=this.#Tt;const a=this.#vt;const l=this.#Rt;const u=t.#Mt;const w=t.#It;const h=t.#St;const f=t.#zt;const d=t.#At;const C=t.#xt;const B=t.#Tt;const E=t.#vt;const g=t.#Rt;return new PerspectiveTransform(e*u+o*w+c*h,e*f+o*d+c*C,e*B+o*E+c*g,n*u+r*w+a*h,n*f+r*d+a*C,n*B+r*E+a*g,s*u+i*w+l*h,s*f+i*d+l*C,s*B+i*E+l*g)}mapping(t,e){const n=this.#Mt;const s=this.#It;const o=this.#St;const r=this.#zt;const i=this.#At;const c=this.#xt;const a=this.#Tt;const l=this.#vt;const u=this.#Rt;const w=o*t+c*e+u;return[(n*t+r*e+a)/w,(s*t+i*e+l)/w]}}function squareToQuadrilateral(t,e,n,s,o,r,i,c){const a=t-n+o-i;const l=e-s+r-c;if(a===0&&l===0)return new PerspectiveTransform(n-t,o-n,t,s-e,r-s,e,0,0,1);{const u=n-o;const w=i-o;const h=s-r;const f=c-r;const d=u*f-w*h;const C=(a*f-w*l)/d;const B=(u*l-a*h)/d;return new PerspectiveTransform(n-t+C*n,i-t+B*i,t,s-e+C*s,c-e+B*c,e,C,B,1)}}function quadrilateralToSquare(t,e,n,s,o,r,i,c){return squareToQuadrilateral(t,e,n,s,o,r,i,c).inverse()}function quadrilateralToQuadrilateral(t,e,n,s,o,r,i,c,a,l,u,w,h,f,d,C){const B=quadrilateralToSquare(t,e,n,s,o,r,i,c);const E=squareToQuadrilateral(a,l,u,w,h,f,d,C);return E.times(B)}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function createTransform(t,e){let n;let s;let o;let r;const{x:i,y:c}=t.topLeft;const{x:a,y:l}=t.topRight;const{x:u,y:w}=t.bottomLeft;const h=FinderPatternGroup.size(t)-3.5;if(e!=null){n=e.x;s=e.y;o=h-3;r=o}else{n=a+u-i;s=l+w-c;o=h;r=h}return quadrilateralToQuadrilateral(3.5,3.5,h,3.5,o,r,3.5,h,i,c,a,l,n,s,u,w)}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function calculateEstimateTimingRatio(t,e){return e>t?1:e<t?-1:0}function getEstimateTimingPointXAxis(t,e){const[n,,s]=Pattern.rect(t);return e>0?s:e<0?n:t.x}function getEstimateTimingPointYAxis(t,e){const[,n,,s]=Pattern.rect(t);return e>0?s:e<0?n:t.y}function getEstimateTimingLine(t,e,n,s){const{x:o,y:r}=e;const{x:i,y:c}=t;const{x:a,y:l}=n;const u=calculateEstimateTimingRatio(o,a);const w=calculateEstimateTimingRatio(r,l);const h=getEstimateTimingPointXAxis(e,u);const f=getEstimateTimingPointYAxis(e,w);const d=getEstimateTimingPointXAxis(t,u);const C=getEstimateTimingPointYAxis(t,w);return u===0||w===0?[new Point(d,C),new Point(h,f)]:(s?u===w:u!==w)?[new Point(i,C),new Point(o,f)]:[new Point(d,c),new Point(h,r)]}function isValidTimingLine(t,e,n,s){const o=s+8;const r=new PlotLine(e,n).points();let i=1;let c=t.get(toInt32(e.x),toInt32(e.y));for(const[e,n]of r){const s=t.get(e,n);if(s!==c){i++;c=s;if(i>o)return false}}return i>=s-14-Math.max(2,(s-17)/4)}function checkEstimateTimingLine(t,e,n){const{topLeft:s,topRight:o,bottomLeft:r}=e;const[i,c]=n?getEstimateTimingLine(s,r,o,true):getEstimateTimingLine(s,o,r);return isValidTimingLine(t,i,c,FinderPatternGroup.size(e))}function checkMappingTimingLine(t,e,n,s){const[o,r]=e.mapping(s?6.5:7.5,s?7.5:6.5);const[i,c]=e.mapping(s?6.5:n-7.5,s?n-7.5:6.5);return isValidTimingLine(t,new Point(o,r),new Point(i,c),n)}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class PatternRatios{#Dt;#lt;constructor(t){this.#lt=t;this.#Dt=accumulate(t)}get modules(){return this.#Dt}get ratios(){return this.#lt}}const v=new PatternRatios([1,1,3,1,1]);const R=new PatternRatios([1,1,1,1,1]);const D=new PatternRatios([1,1,1]);
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function calculateScanlineNoise(t,{ratios:e,modules:n}){let s=0;const{length:o}=e;const r=accumulate(t);const i=r/n;for(let n=0;n<o;n++)s+=Math.abs(t[n]-e[n]*i);return[s/r,i]}function sumScanlineNonzero(t){let e=0;for(const n of t){if(n===0)return NaN;e+=n}return e}function scanlineUpdate(t,e){const{length:n}=t;const s=n-1;for(let e=0;e<s;e++)t[e]=t[e+1];t[s]=e}function getCrossScanline(t,e,n,s,o){e=toInt32(e);n=toInt32(n);let r=o?n:e;const i=[0,0,0,0,0];const c=o?t.height:t.width;const isBlackPixel=()=>o?t.get(e,r):t.get(r,n);while(r>=0&&isBlackPixel()){r--;i[2]++}while(r>=0&&!isBlackPixel()){r--;i[1]++}while(r>=0&&i[0]<s&&isBlackPixel()){r--;i[0]++}r=(o?n:e)+1;while(r<c&&isBlackPixel()){r++;i[2]++}while(r<c&&!isBlackPixel()){r++;i[3]++}while(r<c&&i[4]<s&&isBlackPixel()){r++;i[4]++}return[i,r]}function getDiagonalScanline(t,e,n,s,o){e=toInt32(e);n=toInt32(n);let r=-1;let i=e;let c=n;const a=[0,0,0,0,0];const{width:l,height:u}=t;const w=o?-1:1;const updateAxis=()=>{i+=r;c-=r*w};const isBlackPixel=()=>t.get(i,c);while(i>=0&&c>=0&&c<u&&isBlackPixel()){updateAxis();a[2]++}while(i>=0&&c>=0&&c<u&&!isBlackPixel()){updateAxis();a[1]++}while(i>=0&&c>=0&&c<u&&a[0]<s&&isBlackPixel()){updateAxis();a[0]++}r=1;i=e+r;c=n-r*w;while(i<l&&c>=0&&c<u&&isBlackPixel()){updateAxis();a[2]++}while(i<l&&c>=0&&c<u&&!isBlackPixel()){updateAxis();a[3]++}while(i<l&&c>=0&&c<u&&a[4]<s&&isBlackPixel()){updateAxis();a[4]++}return a}function centerFromScanlineEnd(t,e){const n=[];const s=toInt32(t.length/2);for(let e=0;e<=s;e++){const o=s+e+1;n.push(accumulate(t,s-e,o)/2+accumulate(t,o))}return e-(n[0]*2+accumulate(n,1))/(s+2)}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const F=Math.PI/180;const N=.625;const O=.5;const V=.5;const L=F*40;const _=F*140;
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function isDiagonalScanlineCheckPassed(t,e,n,s){return s?isMatchPattern(t,n)&&isMatchPattern(e,n):isMatchPattern(t,n)||isMatchPattern(e,n)}function alignCrossPattern(t,e,n,s,o,r){const[i,c]=getCrossScanline(t,e,n,s,r);return[isMatchPattern(i,o)?centerFromScanlineEnd(i,c):NaN,i]}function isEqualsSize(t,e,n){t>e&&([t,e]=[e,t]);return e-t<=e*n}function isMatchPattern(t,{ratios:e,modules:n}){const{length:s}=t;const o=sumScanlineNonzero(t);if(o>=n){const r=o/n;const i=r*N+O;for(let n=0;n<s;n++){const s=e[n];const o=t[n];const c=Math.abs(o-r*s);if(c>i)return false}return true}return false}function calculatePatternNoise(t,...e){let n=0;let s=0;const{length:o}=e;const r=[];for(const s of e){const[e,o]=calculateScanlineNoise(s,t);n+=e;r.push(o)}const i=accumulate(r);const c=i/o;for(const t of r)s+=Math.abs(t-c);return n+s/i}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class PatternFinder{#Ft;#S;#lt;#pt=[];constructor(t,e,n){this.#S=t;this.#lt=e;this.#Ft=n}get matrix(){return this.#S}get patterns(){return this.#pt}match(t,e,n,s){const o=this.#S;const r=this.#lt;let i=centerFromScanlineEnd(n,t);const[c,a]=alignCrossPattern(o,i,e,s,r,true);if(c>=0){let t;[i,t]=alignCrossPattern(o,i,c,s,r);if(i>=0){const e=getDiagonalScanline(o,i,c,s);const n=getDiagonalScanline(o,i,c,s,true);if(isDiagonalScanlineCheckPassed(e,n,r,this.#Ft)){const s=calculatePatternNoise(r,t,a,e,n);const o=accumulate(t);const l=accumulate(a);const u=this.#pt;const{length:w}=u;let h=false;for(let t=0;t<w;t++){const e=u[t];if(Pattern.equals(e,i,c,o,l)){h=true;u[t]=Pattern.combine(e,i,c,o,l,s);break}}h||u.push(new Pattern(r,i,c,o,l,s))}}}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function isGroupNested(t,e,n){let s=0;const{topLeft:o,topRight:r,bottomLeft:i}=t;for(const c of e)if(c!==o&&c!==r&&c!==i){let e;if(n.has(c)){e=FinderPatternGroup.contains(t,c);if(e)return true}if(Pattern.noise(c)<1&&(e==null?FinderPatternGroup.contains(t,c):e)&&++s>3)return true}return false}class FinderPatternFinder extends PatternFinder{constructor(t,e){super(t,v,e)}*groups(){const t=this.patterns.filter((t=>Pattern.combined(t)>=3&&Pattern.noise(t)<=1.5));const{length:e}=t;if(e===3){const e=new FinderPatternGroup(this.matrix,t);const n=FinderPatternGroup.size(e);n>=C&&n<=B&&(yield e)}else if(e>3){const n=e-2;const s=e-1;const o=new Map;for(let r=0;r<n;r++){const n=t[r];const i=n.moduleSize;if(!o.has(n))for(let c=r+1;c<s;c++){const s=t[c];const r=s.moduleSize;if(o.has(n))break;if(!o.has(s)&&isEqualsSize(i,r,V))for(let a=c+1;a<e;a++){const e=t[a];const c=e.moduleSize;if(o.has(n)||o.has(s))break;if(!isEqualsSize(i,c,V)||!isEqualsSize(r,c,V))continue;const{matrix:l}=this;const u=new FinderPatternGroup(l,[n,s,e]);const w=calculateTopLeftAngle(u);if(w>=L&&w<=_){const[r,i]=FinderPatternGroup.moduleSizes(u);if(r>=1&&i>=1){const{topLeft:c,topRight:a,bottomLeft:w}=u;const h=distance(c,a);const f=distance(c,w);const d=round(h/r);const E=round(f/i);if(Math.abs(d-E)<=4){const r=FinderPatternGroup.size(u);if(r>=C&&r<=B&&!isGroupNested(u,t,o)&&(checkEstimateTimingLine(l,u)||checkEstimateTimingLine(l,u,true))&&(yield u)){o.set(n,true);o.set(s,true);o.set(e,true)}}}}}}}}}find(t,e,n,s){const{matrix:o}=this;const r=t+n;const i=e+s;const match=(t,e,n,s,o,r)=>{scanlineUpdate(n,s);scanlineUpdate(o,r);o[0]===1&&o[1]===0&&o[2]===1&&o[3]===0&&o[4]===1&&isMatchPattern(n,v)&&this.match(t,e,n,n[2])};for(let n=e;n<i;n++){let e=t;while(e<r&&!o.get(e,n))e++;let s=0;let i=o.get(e,n);const c=[0,0,0,0,0];const a=[-1,-1,-1,-1,-1];while(e<r){const t=o.get(e,n);if(t===i)s++;else{match(e,n,c,s,a,i);s=1;i=t}e++}match(e,n,c,s,a,i)}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */class AlignmentPatternFinder extends PatternFinder{constructor(t,e){super(t,R,e)}filter(t,e){const n=this.patterns.filter((t=>Pattern.noise(t)<=2.5&&isEqualsSize(t.moduleSize,e,V)));n.length>1&&n.sort(((n,s)=>{const o=Pattern.noise(n);const r=Pattern.noise(s);const i=Math.abs(n.moduleSize-e);const c=Math.abs(s.moduleSize-e);const a=(distance(n,t)+i)*o;const l=(distance(s,t)+c)*r;return a-l}));const s=n.slice(0,2);s.push(t);return s}find(t,e,n,s){const{matrix:o}=this;const r=t+n;const i=e+s;const match=(t,e,n,s,o,r)=>{scanlineUpdate(n,s);scanlineUpdate(o,r);o[0]===0&&o[1]===1&&o[2]===0&&isMatchPattern(n,D)&&this.match(t,e,n,n[1])};for(let n=e;n<i;n++){let e=t;while(e<r&&!o.get(e,n))e++;let s=0;let i=o.get(e,n);const c=[0,0,0];const a=[-1,-1,-1];while(e<r){const t=o.get(e,n);if(t===i)s++;else{match(e,n,c,s,a,i);s=1;i=t}e++}match(e,n,c,s,a,i)}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getExpectAlignment(t){const{x:e,y:n}=t.topLeft;const s=FinderPatternGroup.size(t);const o=1-3/(s-7);const r=FinderPatternGroup.bottomRight(t);const[i,c]=FinderPatternGroup.moduleSizes(t);const a=e+(r.x-e)*o;const l=n+(r.y-n)*o;return new Pattern(R,a,l,i*5,c*5,0)}function findAlignmentInRegion(t,e,n){const s=FinderPatternGroup.size(e);const o=Math.min(20,toInt32(s/4));const r=getExpectAlignment(e);const i=new AlignmentPatternFinder(t,n);const c=FinderPatternGroup.moduleSize(e);const{x:a,y:l}=r;const u=Math.ceil(c*o);const w=toInt32(Math.max(0,l-u));const h=toInt32(Math.max(0,a-u));const f=toInt32(Math.min(t.width-1,a+u));const d=toInt32(Math.min(t.height-1,l+u));i.find(h,w,f-h,d-w);return i.filter(r,c)}class Detector{#Nt;
/**
   * @constructor
   * @param options The options of detector.
   */
constructor(t={}){this.#Nt=t}
/**
   * @method detect Detect the binarized image matrix.
   * @param matrix The binarized image matrix.
   */*detect(t){const{strict:e}=this.#Nt;const{width:n,height:s}=t;const o=new FinderPatternFinder(t,e);o.find(0,0,n,s);const r=o.groups();let i=r.next();while(!i.done){let n=false;const s=i.value;const o=FinderPatternGroup.size(s);if(o>=g){const r=findAlignmentInRegion(t,s,e);for(const e of r){const r=createTransform(s,e);if(checkMappingTimingLine(t,r,o)&&checkMappingTimingLine(t,r,o,true)){n=yield new Detected(t,r,s,e);if(n)break}}}else{const e=createTransform(s);checkMappingTimingLine(t,e,o)&&checkMappingTimingLine(t,e,o,true)&&(n=yield new Detected(t,e,s))}i=r.next(n)}}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getHanziCode(t){const e=n.get(t);return e!=null?e:NaN}class Hanzi{#et;
/**
   * @constructor
   * @param content The content to encode.
   */
constructor(t){assertContent(t);this.#et=t}get mode(){return Mode.HANZI}get content(){return this.#et}encode(){const t=new BitArray;const e=this.#et;for(const n of e){let e=getHanziCode(n);if(e>=41377&&e<=43774)e-=41377;else{if(!(e>=45217&&e<=64254))throw new Error(`illegal hanzi character: ${n}`);e-=42657}e=96*(e>>8)+(e&255);t.append(e,13)}return t}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getKanjiCode(t){const e=s.get(t);return e!=null?e:NaN}class Kanji{#et;
/**
   * @constructor
   * @param content The content to encode.
   */
constructor(t){assertContent(t);this.#et=t}get mode(){return Mode.KANJI}get content(){return this.#et}encode(){const t=new BitArray;const e=this.#et;for(const n of e){let e=getKanjiCode(n);if(e>=33088&&e<=40956)e-=33088;else{if(!(e>=57408&&e<=60351))throw new Error(`illegal kanji character: ${n}`);e-=49472}e=192*(e>>8)+(e&255);t.append(e,13)}return t}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const G=5;const U=8-G;const H=1<<G;function calculateBlackPoint(t){let e=0;let n=0;let s=0;const{length:o}=t;for(let r=0;r<o;r++){if(t[r]>n){e=r;n=t[r]}t[r]>s&&(s=t[r])}let r=0;let i=0;for(let n=0;n<o;n++){const s=n-e;const o=t[n]*s*s;if(o>i){r=n;i=o}}e>r&&([e,r]=[r,e]);if(r-e<=H/16)return-1;let c=-1;let a=r-1;for(let n=r-1;n>e;n--){const o=n-e;const i=o*o*(r-n)*(s-t[n]);if(i>c){a=n;c=i}}return a<<U}function histogram(t,e,n){const s=new BitMatrix(e,n);const o=new Int32Array(H);for(let s=1;s<5;s++){const r=toInt32(e*4/5);const i=toInt32(n*s/5)*e;for(let n=toInt32(e/5);n<r;n++){const e=t[i+n];o[e>>U]++}}const r=calculateBlackPoint(o);if(r>0)for(let o=0;o<n;o++){const n=o*e;for(let i=0;i<e;i++){const e=t[n+i];e<r&&s.set(i,o)}}return s}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */const q=3;const W=24;const $=1<<q;const j=$-1;const Z=$*5;function calculateSubSize(t){let e=t>>q;t&j&&e++;return e}function clamp(t,e){return t<2?2:Math.min(t,e)}function calculateOffset(t,e){t<<=q;return t>e?e:t}function calculateBlackPoints(t,e,n){const s=[];const o=e-$;const r=n-$;const i=calculateSubSize(e);const c=calculateSubSize(n);for(let n=0;n<c;n++){s[n]=new Int32Array(i);const c=calculateOffset(n,r);for(let r=0;r<i;r++){let i=0;let a=0;let l=255;const u=calculateOffset(r,o);for(let n=0,s=c*e+u;n<$;n++,s+=e){for(let e=0;e<$;e++){const n=t[s+e];i+=n;n<l&&(l=n);n>a&&(a=n)}if(a-l>W)for(n++,s+=e;n<$;n++,s+=e)for(let e=0;e<$;e++)i+=t[s+e]}let w=i>>q*2;if(a-l<=W){w=l/2;if(n>0&&r>0){const t=(s[n-1][r]+2*s[n][r-1]+s[n-1][r-1])/4;l<t&&(w=t)}}s[n][r]=w}}return s}function adaptiveThreshold(t,e,n){const s=e-$;const o=n-$;const r=calculateSubSize(e);const i=calculateSubSize(n);const c=new BitMatrix(e,n);const a=calculateBlackPoints(t,e,n);for(let n=0;n<i;n++){const l=clamp(n,i-3);const u=calculateOffset(n,o);for(let n=0;n<r;n++){let o=0;const i=clamp(n,r-3);const w=calculateOffset(n,s);for(let t=-2;t<=2;t++){const e=a[l+t];o+=e[i-2]+e[i-1]+e[i]+e[i+1]+e[i+2]}const h=o/25;for(let n=0,s=u*e+w;n<$;n++,s+=e)for(let e=0;e<$;e++)t[s+e]<=h&&c.set(w+e,u+n)}}return c}
/**
 * @function grayscale
 * @description Convert an image to grayscale.
 * @param image The image data to convert.
 */function grayscale({data:t,width:e,height:n}){const s=new Uint8Array(e*n);for(let o=0;o<n;o++){const n=o*e;for(let o=0;o<e;o++){const e=n+o;const r=e*4;const i=t[r];const c=t[r+1];const a=t[r+2];s[n+o]=i*306+c*601+a*117+512>>10}}return s}
/**
 * @function binarize
 * @description Convert the image to a binary matrix.
 * @param luminances The luminances of the image.
 * @param width The width of the image.
 * @param height The height of the image.
 */function binarize(t,e,n){if(t.length!==e*n)throw new Error("luminances length must be equals to width * height");return e<Z||n<Z?histogram(t,e,n):adaptiveThreshold(t,e,n)}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getNumericCode(t){const e=r.get(t);if(e!=null)return e;throw new Error(`illegal numeric character: ${t}`)}class Numeric{#et;
/**
   * @constructor
   * @param content The content to encode.
   */
constructor(t){assertContent(t);this.#et=t}get mode(){return Mode.NUMERIC}get content(){return this.#et}encode(){const t=new BitArray;const e=Array.from(this.#et);const{length:n}=e;for(let s=0;s<n;){const o=getNumericCode(e[s]);if(s+2<n){const n=getNumericCode(e[s+1]);const r=getNumericCode(e[s+2]);t.append(o*100+n*10+r,10);s+=3}else if(s+1<n){const n=getNumericCode(e[s+1]);t.append(o*10+n,7);s+=2}else{t.append(o,4);s++}}return t}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */function getAlphanumericCode(t){const e=c.get(t);if(e!=null)return e;throw new Error(`illegal alphanumeric character: ${t}`)}class Alphanumeric{#et;
/**
   * @constructor
   * @param content The content to encode.
   */
constructor(t){assertContent(t);this.#et=t}get mode(){return Mode.ALPHANUMERIC}get content(){return this.#et}encode(){const t=new BitArray;const e=Array.from(this.#et);const{length:n}=e;for(let s=0;s<n;){const o=getAlphanumericCode(e[s]);if(s+1<n){const n=getAlphanumericCode(e[s+1]);t.append(o*45+n,11);s+=2}else{t.append(o,6);s++}}return t}}
/**
 * @module QRCode
 * @package @nuintun/qrcode
 * @license MIT
 * @version 5.0.2
 * @author nuintun <nuintun@qq.com>
 * @description A pure JavaScript QRCode encode and decode library.
 * @see https://github.com/nuintun/qrcode#readme
 */export{Alphanumeric,BitMatrix,Byte,Charset,Decoder,Detector,Encoder,Hanzi,Kanji,Numeric,binarize,grayscale};

