
#Область ПрограммныйИнтерфейс

// Обработчик элемента очереди в режиме работы бота - Чат игра
// 
// Параметры:
//  ДанныеЭлемента - Структура
Процедура ПриОбработкеЭлементаОчереди(ДанныеЭлемента) Экспорт
	
	Если ДанныеЭлемента.Свойство("message") Тогда
		
		Сообщение = ДанныеЭлемента.message;
		
		Если Не Сообщение.Свойство("from") Тогда
			Возврат;
		КонецЕсли;
		
		Если Не Сообщение.Свойство("text") Тогда
			Возврат;
		КонецЕсли;

		Отправитель = Сообщение.from.id;
		Текст = Сообщение.text;
		
		СостояниеИгрока = ПроверкаСостоянияИгрока(Отправитель);
		ИгрокПодключается = ИгрокПытаетсяПодключиться(Отправитель);
		
		Если Текст = "Создать новую игру" и СостояниеИгрока = "ВнеИгры" Тогда
			СоздатьНовуюСессию(Отправитель);		
		ИначеЕсли Текст = "Присоединиться к игре" и СостояниеИгрока = "ВнеИгры" и не ИгрокПодключается Тогда
			НачатьСоединение(Отправитель);	
		ИначеЕсли Текст = "Выйти из режима ожидания" и СостояниеИгрока = "ОжиданиеИгры" Тогда
			СбросСессии(Отправитель);		
		ИначеЕсли Текст = "Вернуться назад" и СостояниеИгрока = "ВнеИгры" и ИгрокПодключается Тогда
			СбросПодключения(Отправитель);	
		ИначеЕсли ИгрокПодключается и СостояниеИгрока = "ВнеИгры" Тогда
			ПроверкаКодаПодключения(Отправитель, Текст);	
		ИначеЕсли Текст = "Выйти из игры" и (СостояниеИгрока = "КонецИгры" или СостояниеИгрока = "Игра") Тогда
			СбросСессионнойИгры(Отправитель);
			
			
		// Сделать после игры
		ИначеЕсли Текст = "Повторить игру" и (СостояниеИгрока = "КонецИгры" или СостояниеИгрока = "Игра") Тогда 
			НачатьИгруЗаново(Отправитель);	

		// В первую очередь сделать	!!
		ИначеЕсли СостояниеИгрока = "Игра" Тогда
			НачатьИгру(Отправитель, Текст);
		
		
		Иначе
			ПредложитьВыбратьДействия(Отправитель, СостояниеИгрока);
		КонецЕсли;
			
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ПроверкаСостоянияИгрока(Отправитель)
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.СтатусИгры
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии
		|ГДЕ
		|	ЧатИграСессии.ПервыйИгрок = &ТекИгрок
		|	ИЛИ ЧатИграСессии.ВторойИгрок = &ТекИгрок";
	Запрос.УстановитьПараметр("ТекИгрок", Отправитель);
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
	Если Выборка.Следующий() Тогда
		Если Выборка.СтатусИгры = Перечисления.СтатусыИгры.КонецИгры Тогда
			Возврат "КонецИгры";
		ИначеЕсли Выборка.СтатусИгры = Перечисления.СтатусыИгры.Игра Тогда
			Возврат "Игра";
		Иначе
			Возврат "ОжиданиеИгры";
		КонецЕсли;
	Иначе
		Возврат "ВнеИгры";		
	КонецЕсли;
КонецФункции

Функция ИгрокПытаетсяПодключиться(Отправитель)
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграПодключениеИгрока.Код
		|ИЗ
		|	Справочник.ЧатИграПодключениеИгрока КАК ЧатИграПодключениеИгрока
		|ГДЕ
		|	ЧатИграПодключениеИгрока.Игрок = &Игрок";
	Запрос.УстановитьПараметр("Игрок", Отправитель);
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
	Если Выборка.Следующий() Тогда
		Возврат Истина;
	Иначе
		Возврат Ложь;		
	КонецЕсли;
КонецФункции

Процедура СоздатьНовуюСессию(Отправитель)
	
	СуществующиеКоды = Новый Массив;

	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.КодДляСоединения
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии";
	
	РезультатЗапроса = Запрос.Выполнить();
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		СуществующиеКоды.Добавить(ВыборкаДетальныеЗаписи.КодДляСоединения);
	КонецЦикла;
	
	НоваяСессия = Справочники.ЧатИграСессии.СоздатьЭлемент();
	НоваяСессия.ПервыйИгрок = Отправитель;
	НоваяСессия.СтатусИгры = Перечисления.СтатусыИгры.ОжиданиеВторогоИгрока;
	
	НовыйКод = НовыйКодДляСоединения();
	Пока СуществующиеКоды.Найти(НовыйКод) = 0 Цикл
		НовыйКод = НовыйКодДляСоединения();	
	КонецЦикла;
	НоваяСессия.КодДляСоединения = НовыйКод;

	НоваяСессия.Записать();	
	
	Шабл = "Сейчас вы в режиме ожидания соперника. Код для подключения соперника: %1";
	ТекстСообщения = СтрШаблон(Шабл, НовыйКод);
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();
	ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВРежимеОжидания();
	ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, ТекстСообщения, ДополнительныеСвойства);
	
КонецПроцедуры

Функция НовыйКодДляСоединения()
	
	Генератор = Новый ГенераторСлучайныхЧисел();
	НовыйКодДляСоединения = Строка(Генератор.СлучайноеЧисло(1, 999999));
	
	Пока СтрДлина(НовыйКодДляСоединения) < 7 Цикл
		НовыйКодДляСоединения = "0" + НовыйКодДляСоединения;
	КонецЦикла;
	
	Возврат НовыйКодДляСоединения;
	
КонецФункции

Процедура СбросСессии(Отправитель);

	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.Ссылка
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии
		|ГДЕ
		|	ЧатИграСессии.ПервыйИгрок = &ТекИгрок";
	
	Запрос.УстановитьПараметр("ТекИгрок", Отправитель);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Если ВыборкаДетальныеЗаписи.Следующий() Тогда
		Объект = ВыборкаДетальныеЗаписи.Ссылка.ПолучитьОбъект();
		Объект.Удалить();	
	КонецЕсли;;

	ТекстСообщения = "Вы вышли из режима ожидания соперника. Выберите желаемое действие с клавиатуры";
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();
	ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВЛобби();
	ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, ТекстСообщения, ДополнительныеСвойства);
	
КонецПроцедуры

Процедура НачатьСоединение(Отправитель)
	НоваяСессия = Справочники.ЧатИграПодключениеИгрока.СоздатьЭлемент();
	НоваяСессия.Игрок = Отправитель;
	НоваяСессия.Записать();
	
	СтрокиКлавиатуры = Новый Массив;
	
	СтрокаКлавиатуры = Новый Массив;
	Кнопка = Новый Структура;
	Кнопка.Вставить("text", "Вернуться назад");
	СтрокаКлавиатуры.Добавить(Кнопка);
	СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
		
	Клавиатура = Новый Структура;
	Клавиатура.Вставить("keyboard", СтрокиКлавиатуры);
	Клавиатура.Вставить("resize_keyboard", Истина);	
	
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();
	ДополнительныеСвойства.Клавиатура = Клавиатура;
	ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, "Введите код подключения к игре", ДополнительныеСвойства);		
	
КонецПроцедуры

Процедура ПроверкаКодаПодключения(Отправитель, ВведеныйКод)
	
	ПроверочныйКод = Сред(ВведеныйКод, 1, 3) + " " + Сред(ВведеныйКод, 4);
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.Ссылка КАК СсылкаСессии
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии
		|ГДЕ
		|	ЧатИграСессии.КодДляСоединения = &КодДляСоединения
		|	ИЛИ ЧатИграСессии.КодДляСоединения = &КодДляСоединенияБезПробела";
	Запрос.УстановитьПараметр("КодДляСоединения", ПроверочныйКод);
	Запрос.УстановитьПараметр("КодДляСоединенияБезПробела", ВведеныйКод);
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
		
	Если Выборка.Следующий() Тогда
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ
			|	ЧатИграПодключениеИгрока.Ссылка
			|ИЗ
			|	Справочник.ЧатИграПодключениеИгрока КАК ЧатИграПодключениеИгрока
			|ГДЕ
			|	ЧатИграПодключениеИгрока.Игрок = &Игрок";	
		Запрос.УстановитьПараметр("Игрок", Отправитель);
		РезультатЗапроса = Запрос.Выполнить();

		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
		Если ВыборкаДетальныеЗаписи.Следующий() Тогда
			Объект = ВыборкаДетальныеЗаписи.Ссылка.ПолучитьОбъект();
			Объект.Удалить();
		КонецЕсли;
		
		ТекИгра = Выборка.СсылкаСессии.ПолучитьОбъект();
		Если ТекИгра.ПервыйИгрок = Отправитель Тогда
			ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, "Вы не можете подключиться к своей игре");
			
		Иначе
			ТекИгра.ВторойИгрок = Отправитель;
			ТекИгра.СтатусИгры = Перечисления.СтатусыИгры.Игра;
			ТекИгра.Записать();
			ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();
			ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВКонцеИгры();
			ИнтеграцияТелеграм.ОтправитьСообщение(ТекИгра.ПервыйИгрок,
			 									"Соперник подключен! Теперь вы можете играть!",
			  									ДополнительныеСвойства);
			ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель,
			 									"Игра найдена. Теперь вы можете играть!",
			  									ДополнительныеСвойства);
		КонецЕсли;
		
	Иначе
		ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, "Игра не найдена. Введите код ещё раз");
	КонецЕсли;
	
КонецПроцедуры

Процедура СбросПодключения(Отправитель)
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграПодключениеИгрока.Ссылка
		|ИЗ
		|	Справочник.ЧатИграПодключениеИгрока КАК ЧатИграПодключениеИгрока
		|ГДЕ
		|	ЧатИграПодключениеИгрока.Игрок = &Игрок";	
	Запрос.УстановитьПараметр("Игрок", Отправитель);
	РезультатЗапроса = Запрос.Выполнить();

	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	Если ВыборкаДетальныеЗаписи.Следующий() Тогда
		Объект = ВыборкаДетальныеЗаписи.Ссылка.ПолучитьОбъект();
		Объект.Удалить();
	КонецЕсли;
	
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();
	ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВЛобби();
	ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, "Выберите действие с помощью клавиатуры", ДополнительныеСвойства);	

КонецПроцедуры

// СДЕЛАТЬ ИГРУ
Процедура НачатьИгру(Отправитель, Текст)

	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.ПервыйИгрок,
		|	ЧатИграСессии.ВторойИгрок
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии
		|ГДЕ
		|	ЧатИграСессии.ПервыйИгрок = &ТекИгрок
		|	ИЛИ ЧатИграСессии.ВторойИгрок = &ТекИгрок";	
	Запрос.УстановитьПараметр("ТекИгрок", Отправитель);
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	Пока Выборка.Следующий() Цикл
		Если Выборка.ПервыйИгрок = Отправитель Тогда
			Соперник = Выборка.ВторойИгрок;
		Иначе
			Соперник = Выборка.ПервыйИгрок;
		КонецЕсли;
	КонецЦикла;
	
	ИнтеграцияТелеграм.ОтправитьСообщение(Соперник, Текст);
	
КонецПроцедуры

Процедура СбросСессионнойИгры(Отправитель)
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.Ссылка КАК Ссылка
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии
		|ГДЕ
		|	ЧатИграСессии.ПервыйИгрок = &ТекИгрок
		|	ИЛИ ЧатИграСессии.ВторойИгрок = &ТекИгрок";
	Запрос.УстановитьПараметр("ТекИгрок", Отправитель);
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	Если ВыборкаДетальныеЗаписи.Следующий() Тогда
		Объект = ВыборкаДетальныеЗаписи.Ссылка.ПолучитьОбъект();
		
		ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();
		ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВЛобби();
		
		ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, 
										"Вы вышли из игры. Выберите желаемое действие с клавиатуры",
										 ДополнительныеСвойства);
		Если Объект.ПервыйИгрок = Отправитель Тогда
			ИнтеграцияТелеграм.ОтправитьСообщение(Объект.ВторойИгрок,
										 "Ваш соперник вышел из игры. Выберите желаемое действие с клавиатуры",
										  ДополнительныеСвойства);
		Иначе
			ИнтеграцияТелеграм.ОтправитьСообщение(Объект.ПервыйИгрок,
										 "Ваш соперник вышел из игры. Выберите желаемое действие с клавиатуры",
										  ДополнительныеСвойства);
		КонецЕсли;
			
		Объект.Удалить();	
	КонецЕсли;;
	
КонецПроцедуры

// СДЕЛАТЬ ПРОЦЕДУРУ ПОВТОРА ИГРЫ
Процедура НачатьИгруЗаново(Отправитель)
	
	
	
	
КонецПроцедуры

Процедура ПредложитьВыбратьДействия(Отправитель, Состояние)
	
	ТекстСообщения = "Действий не найдено!";
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();	
	Если Состояние = "ВнеИгры" Тогда
		ТекстСообщения = "Выберите действие с помощью клавиатуры";
		ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВЛобби();
	ИначеЕсли Состояние = "КонецИгры" Тогда
		ТекстСообщения = "Выберите действие с помощью клавиатуры";
		ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВКонцеИгры();
	ИначеЕсли Состояние = "ОжиданиеИгры" Тогда
		Шабл = "Сейчас вы в режиме ожидания соперника. Код для подключения соперника: %1";
		ТекстСообщения = СтрШаблон(Шабл, ПолучитьКодПодключения(Отправитель));
		ДополнительныеСвойства.Клавиатура = КлавиатураСписокДействийВРежимеОжидания();
	КонецЕсли;
	ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, ТекстСообщения, ДополнительныеСвойства);		
	
КонецПроцедуры

Функция КлавиатураСписокДействийВЛобби()
	
	СтрокиКлавиатуры = Новый Массив;
	
	СтрокаКлавиатуры = Новый Массив;
	Кнопка = Новый Структура;
	Кнопка.Вставить("text", "Создать новую игру");
	СтрокаКлавиатуры.Добавить(Кнопка);
	СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
		
	СтрокаКлавиатуры = Новый Массив;
	Кнопка = Новый Структура;
	Кнопка.Вставить("text", "Присоединиться к игре");
	СтрокаКлавиатуры.Добавить(Кнопка);
	СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
		
	Клавиатура = Новый Структура;
	Клавиатура.Вставить("keyboard", СтрокиКлавиатуры);
	Клавиатура.Вставить("resize_keyboard", Истина);
	
	Возврат Клавиатура;	

КонецФункции

Функция КлавиатураСписокДействийВКонцеИгры()
	
	СтрокиКлавиатуры = Новый Массив;
	
	СтрокаКлавиатуры = Новый Массив;
	Кнопка = Новый Структура;
	Кнопка.Вставить("text", "Начать заново");
	СтрокаКлавиатуры.Добавить(Кнопка);
	СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
		
	СтрокаКлавиатуры = Новый Массив;
	Кнопка = Новый Структура;
	Кнопка.Вставить("text", "Выйти из игры");
	СтрокаКлавиатуры.Добавить(Кнопка);
	СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
		
	Клавиатура = Новый Структура;
	Клавиатура.Вставить("keyboard", СтрокиКлавиатуры);
	Клавиатура.Вставить("resize_keyboard", Истина);	
	
	Возврат Клавиатура;	

КонецФункции

Функция КлавиатураСписокДействийВРежимеОжидания()
	
	СтрокиКлавиатуры = Новый Массив;
	
	СтрокаКлавиатуры = Новый Массив;
	Кнопка = Новый Структура;
	Кнопка.Вставить("text", "Выйти из режима ожидания");
	СтрокаКлавиатуры.Добавить(Кнопка);
	СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
		
	Клавиатура = Новый Структура;
	Клавиатура.Вставить("keyboard", СтрокиКлавиатуры);
	Клавиатура.Вставить("resize_keyboard", Истина);	
	
	Возврат Клавиатура;	

КонецФункции

Функция ПолучитьКодПодключения(Отправитель)
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ЧатИграСессии.КодДляСоединения
		|ИЗ
		|	Справочник.ЧатИграСессии КАК ЧатИграСессии
		|ГДЕ
		|	ЧатИграСессии.ПервыйИгрок = &ТекИгрок
		|	ИЛИ ЧатИграСессии.ВторойИгрок = &ТекИгрок";
	
	Запрос.УстановитьПараметр("ТекИгрок", Отправитель);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Если Выборка.Следующий() Тогда
		Возврат Выборка.КодДляСоединения;
	Иначе
		Возврат 0;		
	КонецЕсли;
	
КонецФункции
	
#КонецОбласти
