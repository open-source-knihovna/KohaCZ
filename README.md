Pravidla vývoje KohaCZ
=
Tento repozitář provozuje česká komunita Koha, která je složená z aktivních zástupců knihoven provozujících tento otevřený knihovní systém a vývojářů. Jeho cílem je soustředit výsledky vývoje lokálních rozšíření a úprav na jedno místo a usnadnit tím samotný voývoj i distribuci.
Do vývoje se může zapojit kdokoli, pokud bude respektovat pravidla sepsaná níže.

Na GitHubu budeme aktivně udržovat dvě větve, [master](https://github.com/open-source-knihovna/KohaCZ/tree/master) a [production](https://github.com/open-source-knihovna/KohaCZ/tree/production).

Master větev kopíruje oficiální repozitář Koha, production je vždy aktuální vychází stable verze (mění se tedy každých cca 6 měsíců). **Veškerý vývoj se posílá do větve master** a to proto, aby byly všechny změny přehledně na jednom místě.

**Změny se aplikují na větev production vždy, když se dokonči logický celek vývoje**, který by stálo za to zavést do produkce. 

Při aplikaci změn je třeba myslet na to, že **větev production může používat jinou verzi, než větev master**. Vždy je nutné při vývoji zvážit možnosti aplikaci patche na master i production. V případě, že to není možné má přednost master větev

Na větvi master se bude vždy vyskytovat **aktuální stable verze** určovaná Koha komunitou. Obdobně se s mírným spožděním bude stable verze vyskytovat i na větvi production.

Po zavedení logického celku do větve production je zapotřebí **nové změny otestovat**. Pokud něco bude nefunkční, nemazat poslední změny, ale **snažit se o jejich opravu**.

Po úspěšném otestování nového kódu se vydá nový [Release](https://github.com/open-source-knihovna/KohaCZ/releases) s následujícím postupem:

1. Vytvoří se nový release tlačítkem *Draft a new release*
2. Do *Tag version* se napíše čislo nové verze
3. V *Target* se **vždy vybere production**
4. Do *Release title* se napíše stručný popis změn
5. Do *Describe this release* se napíše podrobný popis změn včetně výhod a nevýhod zavedení do produkce, pokud tedy nějaké jsou

Pokud z jakéhokoliv důvodu budete chtít vyvíjet na nejnovější verzi Kohy, pak tak čiňte do větve [latest](https://github.com/open-source-knihovna/KohaCZ/tree/latest).

Všechny naše patche je nutné přenést do Bugzilly a nechat projít stadardní cestou schvalování. [Podrobnosti k vývoji na wiki Koha] (http://wiki.koha-community.org/wiki/Category:Development).
