Experimentální větev s REST API
=
<img src="http://online.swagger.io/validator?url=https://koha-devel-test.knihovna-uo.cz/api/v1/" />

V této větvi se snažíme o co nejaktuálnější verzi REST API. Ne všechno je 100% funkční. Ale ledy se hýbou. ;)

Pravidla vývoje KohaCZ
=
[![Gitter](https://badges.gitter.im/open-source-knihovna/KohaCZ.svg)](https://gitter.im/open-source-knihovna/KohaCZ?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Tento repozitář provozuje česká komunita Koha, která je složená z aktivních zástupců knihoven provozujících tento otevřený knihovní systém a vývojářů. Jeho cílem je soustředit výsledky vývoje lokálních rozšíření a úprav na jedno místo a usnadnit tím samotný voývoj i distribuci.
Do vývoje se může zapojit kdokoli, pokud bude respektovat pravidla sepsaná níže.

Na GitHubu budeme aktivně udržovat dvě větve, [master](https://github.com/open-source-knihovna/KohaCZ/tree/master) a [production](https://github.com/open-source-knihovna/KohaCZ/tree/production).

Master větev kopíruje oficiální repozitář Koha, production je vždy aktuální vychází stable verze (mění se tedy každých cca 6 měsíců).

**Změny se aplikují na větev production vždy, když se dokonči logický celek vývoje**, který by stálo za to zavést do produkce. 

Při aplikaci změn je třeba myslet na to, že **větev production může používat jinou verzi, než větev master**. Vždy je nutné při vývoji zvážit možnosti aplikaci patche na master i production. **V případě, že to není možné má přednost master větev.**

Po zavedení logického celku do větve production je zapotřebí **nové změny otestovat**. Pokud se při testování objevní chyby nebo neočekáváné chování, nemazejte poslední změny, ale **snažit se o jejich opravu**. Pokud chcete, abychom váš kód otestovali vložteho jako **pull request**.

Po úspěšném otestování nového kódu se vydá nový [Release](https://github.com/open-source-knihovna/KohaCZ/releases) s následujícím postupem:

1. Vytvoří se nový release tlačítkem *Draft a new release*
2. Do *Tag version* se napíše čislo nové verze
3. V *Target* se **vždy vybere production**
4. Do *Release title* se napíše stručný popis změn
5. Do *Describe this release* se napíše podrobný popis změn včetně výhod a nevýhod zavedení do produkce, pokud tedy nějaké jsou

Všechny naše patche po otestování naším týmem postupně přidáváme do oficiální Bugzilly a necháváme projít stadardní cestou schvalování na kvalitu. [Podrobnosti k vývoji na wiki Koha] (http://wiki.koha-community.org/wiki/Category:Development).

[Seznam](https://github.com/open-source-knihovna/KohaCZ/wiki/Zm%C4%9Bny-v-KohaCZ-oproti-standardn%C3%AD-instalaci) změn v KohaCZ oproti standardní instalaci.

Pokud budete mít jakékoli dotazy k vývoji pište na info@knihovni-system-koha.cz 

![Koha Logo](https://wiki.koha-community.org/w/images/KohaILS.png)
