# New-ZenGL

ZenGL - библиотека создающая рабочее окно для работы с OpenGL.

Платформы: Windows, Linux, MacOS(только Carbon), Android(32), iOS(не проверялось, для старых версий (32) должно работать)

Среда разработки: FPC, Lazarus, Delphi(ограничено)

// ----------------------------------------------------------------------

Последующие изменения: корректирована работа Delphi. Большинство проектов будут работать только в 32-х битной системе Win.

Изменения в версии 0.3.25:
- Вернул функцию вертикальной синхронизации

- Для Windows теперь работает ограничение по выводу кадров. В основном основываясь на частоте монитора. Задать можно 
	вручную.

- Для LCL(VCL)-приложений: редактирована работа с данными приложениями, некоторые функции теперь не работают (не 
	сказывается на работе самого ZenGL), взамен данных функций вам надо использовать стандартные функции для 
	LCL-приложений.

- Сделаны две демо-версии. Работа с 17-й демкой не завершена, но работает. Основываясь на ней можно сделать обычное
	меню для нативных приложений. 18-я демо-версия заменила старую версию LCL-приложения.


Изменения в версии 0.3.24:

- Версия стабильно компилирует под Win64, изменено для версий FPC > 3

- Для Windows, теперь "ALT" + клавиша не вызывает системных звуков

- Для Linux - теперь создаётся рабочая дирректория, но помните!!! Это может быть общий каталог, куда вы "установили"
	свою программу. Поэтому это сделано для тех программ (которые вы создаёте) для которых вы выделяете отдельный
	каталог

- Введено несколько дефайнов:
	- Escape = exit
	- Дефайны для полных версий OpenGL, но пока реализовано только для OpenGL ES, в дальнейшем коснётся и самого
		OpenGL для компьютеров
	- для инициализации под LCL/VCL (handle - окна), по умолчанию включены в данной версии, в следующих версиях
		по умолчанию будет отключено
	- редактированы дефайны под Android, исключён не используемый код

- вернул некоторые функции (которые удалил ранее :/ понял что если человек будет создавать библиотеку, то они нужны 
	будут), некоторые немного изменил, так же исключая повторный и не используемый код

- дополнил OpenGL ES (1.0) отсутствующими, до этого времени, функциями (кроме glColor4f, в данной версии она сделана
	под определённую работу и занята), так же указаны не используемые функции версии 1.1

- дополнил OpenGL недостающими функциями, но немногими, очень много ещё отсутствует


!!! Внимание!!! Поддержка создания библиотек отключена!!! zglHeader.pas не редактирован, и возможно не пригоден для
	использования. Если хотите попробовать, берите его в версии 0.3.12 (так же надо будет восстанавлиать 
	демо-версии как в версии 0.3.12)

	Ещё одна причина отказа от поддержки LCL библиотек, это то, что я не запустил демо-версии на FPC + LCL.
	(Но вот ZenFont(LCL) запустить удалось, так что возможно проблема где-то на поверхности).


- в демо-версии со звуком показано как остановить звуки, для их изначального воспроизведения. Звук теперь можно
	"передвигать" (в версии OpenAL)

- Множественные изменения в файлах, для облегчения кода и более корректной работы. (а возможно и нет...)

- Множественные изменения под разработку под Android. Изменён файл ZenGL.java, корректирована работа Android приложений
	под коснувшиеся изменения.

- ZenFont теперь можно запускать и под Delphi 7. Так же редактирована работа приложения, введены некоторые ограничения
	на работу приложения, для избежания ошибок при создании нового шрифта.

-----------------------------------------------------------------------------------------------------------------------

Дальнейшие планируемые изменения:
- Введение джойстиков/меню для Android, а так же возможность использовать меню и создавать своё на компьютер.

- расширение OpenGL или возможность подключения dglOpenGL (будет возможность создавать умельцам как 3D- приложения,
	так и работы с шейдерами).

- после расширения OpenGL будет поддержка освещения и возможно тумана. И вероятно многое другое, что включено в OpenGL.

- доработка OpenAL. (если руки дойдут)

-----------------------------------------------------------------------------------------------------------------------

Прошу многих извинить!!! Но специально заниматься разработкой/доработкой под MacOS/iOS в данное время не буду. Так же
специальной поддержкой DelphiXE заниматься не буду. Большинство примеров под Delphi 7 будут работать и под DelphiXE
для Windows. Возможно, если DelphiXE поддерживает, будет поддержка Linux. Если DelphiXE поддерживает приложения под
Linux, просьба сообщить мне об этом (сильного желания устанавливать эту среду программирования, нет).

Так же не буду продолжать поддержку DirectX, это в ваших руках, но на это так же надо потратить много времени.


Множество вопросов по работе с ZenGL решены и приведены в примерах. Примеры смотрите под Delphi 7, Lazarus и Android.
Под FP (без Lazarus), MacOS и iOS я не переделывал примеры, их можно так же переделать, подсмотрев в других примерах
указанных выше.

До документации пока руки не дойдут, за это больше всего извиняюсь! На сайте zengl.org смотрите, там достаточно
не мало информации.

-----------------------------------------------------------------------------------------------------------------------

Теперь относительно Android. Google отказалось от поддержки 32-х битных версий программ... а точнее программ, которые
содержат 32-х битный код... 
Это очередная долгая песня. Надо искать скомпилированные библиотеки под 64-х битную систему, и потому в данное время
я этим заниматься не буду.
Если у вас есть данные библиотеками, то вы можете ими поделиться или поделиться ссылками на них. Потому что кроме 
самих библиотек, надо будет и настраивать компиляцию под 64-х битную систему и решать все выявляющиеся проблемы.

Меня устроит и 32-х битная система, так как она вполне запускается и на более поздних версиях телефонов и уж точно
запустится на большинстве телефонов. )))

-----------------------------------------------------------------------------------------------------------------------

Все вопросы можете задавать на форуме сайта zengl.org , или задавая вопросы мне:

M12Mirrel@yandex.ru - почта

https://www.youtube.com/channel/UCn46Rnq_opul3pxkCLtYPYg/featured - канал на ютубе, выкладываю периодически видео
	может кому полезно будет.
	
ну, или так же на форумах, просматриваю темы, по возможности отвечаю (или отмечаю о недоработках для себя)
