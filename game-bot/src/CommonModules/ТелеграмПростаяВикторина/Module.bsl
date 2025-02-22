
#Область ПрограммныйИнтерфейс

// Обработчик элемента очереди в режиме работы бота - Простая викторина
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
		
		Если СтрНачинаетсяС(Текст, "Вопрос") Тогда
			ЗадатьВопрос(Отправитель, Текст);
		Иначе
			ПредложитьВыбратьВопрос(Отправитель);			 
		КонецЕсли;		
		
	КонецЕсли;
		
	Если ДанныеЭлемента.Свойство("callback_query") Тогда
		НажатиеКнопки = ДанныеЭлемента.callback_query;
		ОбработатьНажатиеКнопки(НажатиеКнопки);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции
	
Процедура ЗадатьВопрос(Отправитель, Текст)
	
	НомерВопросаВСообщении = СтрЗаменить(Текст, "Вопрос ", "");
	
	НомерВопросаДляПоиска = НомерВопросаВСообщении;
	
	Пока СтрДлина(НомерВопросаДляПоиска) < 9 Цикл
		НомерВопросаДляПоиска = "0" + НомерВопросаДляПоиска;
	КонецЦикла;
	 
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ВопросыПростойВикторины.Ссылка,
		|	ВопросыПростойВикторины.Наименование,
		|	ВопросыПростойВикторины.Пояснение,
		|	ВопросыПростойВикторины.Картинка,
		|	ВопросыПростойВикторины.Ответы.(
		|		НомерСтроки,
		|		Текст)
		|ИЗ
		|	Справочник.ВопросыПростойВикторины КАК ВопросыПростойВикторины
		|ГДЕ
		|	ВопросыПростойВикторины.Код = &Код";
		
	Запрос.УстановитьПараметр("Код", НомерВопросаДляПоиска);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Не Выборка.Следующий() Тогда
		ТекстОтвета = СтрШаблон("Не найден вопрос с номером %1", НомерВопросаВСообщении);
		ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, ТекстОтвета);
		Возврат;
	КонецЕсли;
	
	ДанныеКартинки = Выборка.Картинка.Получить();
	
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();	
	ДополнительныеСвойства.Клавиатура = ВстроеннаяКлавиатураОтветов(Выборка.Ответы.Выбрать(), Выборка.Ссылка);
	
	ЭлементыВопроса = Новый Массив;
	
	ШаблонЗаголовка = "<b>%1</b>";
	ЭлементыВопроса.Добавить(СтрШаблон(ШаблонЗаголовка, Выборка.Наименование));
	
	Если ЗначениеЗаполнено(Выборка.Пояснение) Тогда
		ЭлементыВопроса.Добавить(Выборка.Пояснение);
	КонецЕсли;
	
	ТекстВопроса = СтрСоединить(ЭлементыВопроса, Символы.ПС);
	
	Если ДанныеКартинки = Неопределено Тогда	
		ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, ТекстВопроса, ДополнительныеСвойства);
	Иначе
		ИнтеграцияТелеграм.ОтправитьКартинку(Отправитель, ДанныеКартинки, ТекстВопроса, ДополнительныеСвойства);
	КонецЕсли;
	
КонецПроцедуры

Функция ВстроеннаяКлавиатураОтветов(Ответы, Ссылка)
	
	
	ИндексКнопки = 0;
	СтрокиКлавиатуры = Новый Массив;
	СтрокаКлавиатуры = Новый Массив;
	
	Пока Ответы.Следующий() Цикл
		
		ИндексКнопки = ИндексКнопки + 1;
		
		ДанныеКнопки = Строка(Ссылка.УникальныйИдентификатор()) + "|" + XMLСтрока(Ответы.НомерСтроки);
		
		Кнопка = Новый Структура;
		Кнопка.Вставить("text", Ответы.Текст);
		Кнопка.Вставить("callback_data", ДанныеКнопки);
		
		СтрокаКлавиатуры.Добавить(Кнопка);
		
		Если ИндексКнопки >= 2 Тогда
			ИндексКнопки = 0;
			СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
			СтрокаКлавиатуры = Новый Массив;
		КонецЕсли;
		
	КонецЦикла;
	
	Если СтрокаКлавиатуры.Количество() > 0 Тогда
		СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
	КонецЕсли;		
	
	Клавиатура = Новый Структура;
	Клавиатура.Вставить("inline_keyboard", СтрокиКлавиатуры);
	
	Возврат Клавиатура;
	
КонецФункции

Процедура ПредложитьВыбратьВопрос(Отправитель)
	
	ТекстСообщения = "Выберите вопрос с помощью клавиатуры";
	
	ДополнительныеСвойства = ИнтеграцияТелеграм.ДополнительныеСвойстваИсходящегоСообщения();	
	ДополнительныеСвойства.Клавиатура = КлавиатураСписокВопросов();
	
	ИнтеграцияТелеграм.ОтправитьСообщение(Отправитель, ТекстСообщения, ДополнительныеСвойства);		
	
КонецПроцедуры

Функция КлавиатураСписокВопросов()
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ВопросыПростойВикторины.Код
		|ИЗ
		|	Справочник.ВопросыПростойВикторины КАК ВопросыПростойВикторины
		|ГДЕ
		|	НЕ ВопросыПростойВикторины.ПометкаУдаления";
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	ИндексКнопки = 0;
	СтрокиКлавиатуры = Новый Массив;
	СтрокаКлавиатуры = Новый Массив;
	
	Пока Выборка.Следующий() Цикл
		
		ИндексКнопки = ИндексКнопки + 1;
		
		ТекстКнопки = СтрШаблон("Вопрос %1", УдалитьЛидирующиеНули(Выборка.Код));
		
		Кнопка = Новый Структура;
		Кнопка.Вставить("text", ТекстКнопки);
		
		СтрокаКлавиатуры.Добавить(Кнопка);
		
		Если ИндексКнопки >= 4 Тогда
			ИндексКнопки = 0;
			СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
			СтрокаКлавиатуры = Новый Массив;
		КонецЕсли;
		
	КонецЦикла;
	
	Если СтрокаКлавиатуры.Количество() > 0 Тогда
		СтрокиКлавиатуры.Добавить(СтрокаКлавиатуры);
	КонецЕсли;		
	
	Клавиатура = Новый Структура;
	Клавиатура.Вставить("keyboard", СтрокиКлавиатуры);
	Клавиатура.Вставить("resize_keyboard", Истина);
	
	Возврат Клавиатура;	

КонецФункции

Функция УдалитьЛидирующиеНули(Строка)
	
	Результат = Строка;
	
	Пока СтрНачинаетсяС(Результат, "0") Цикл
		Результат = Прав(Результат, СтрДлина(Результат - 1));
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

Процедура ОбработатьНажатиеКнопки(НажатиеКнопки)
	
	Если Не НажатиеКнопки.Свойство("from") Тогда
		Возврат;
	КонецЕсли;
	
	Если Не НажатиеКнопки.Свойство("data") Тогда
		Возврат;
	КонецЕсли;
	
	Получатель = НажатиеКнопки.from.id;
	Команда = НажатиеКнопки.data;
	ИдентификаторСообщения = НажатиеКнопки.message.message_id;
	
	ЭтоФото = НажатиеКнопки.message.Свойство("photo");
	
	ЧастиКоманды = СтрРазделить(Команда, "|");
	
	ИдентификаторВопроса = Новый УникальныйИдентификатор(ЧастиКоманды[0]);
	НомерСтроки = Число(ЧастиКоманды[1]);
	
	Вопрос = Справочники.ВопросыПростойВикторины.ПолучитьСсылку(ИдентификаторВопроса);
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ВопросыПростойВикториныОтветы.Ссылка,
		|	ВопросыПростойВикториныОтветы.Текст,
		|	ВопросыПростойВикториныОтветы.Верный,
		|	ВопросыПростойВикториныОтветы.Ссылка.Наименование,
		|	ВопросыПростойВикториныОтветы.Ссылка.Пояснение
		|ИЗ
		|	Справочник.ВопросыПростойВикторины.Ответы КАК ВопросыПростойВикториныОтветы
		|ГДЕ
		|	ВопросыПростойВикториныОтветы.Ссылка = &Ссылка
		|	И ВопросыПростойВикториныОтветы.НомерСтроки = &НомерСтроки";
	Запрос.УстановитьПараметр("Ссылка", Вопрос);
	Запрос.УстановитьПараметр("НомерСтроки", НомерСтроки);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Не Выборка.Следующий() Тогда
		Возврат;
	КонецЕсли;
	
	ЭлементыВопроса = Новый Массив;
	
	ШаблонЗаголовка = "<b>%1</b>";
	ЭлементыВопроса.Добавить(СтрШаблон(ШаблонЗаголовка, Выборка.Наименование));
	
	Если ЗначениеЗаполнено(Выборка.Пояснение) Тогда
		ЭлементыВопроса.Добавить(Выборка.Пояснение);
	КонецЕсли;
	
	ШаблонРезультатаПроверки = "%1: %2";
	
	Если Выборка.Верный Тогда
		ЭлементыВопроса.Добавить(СтрШаблон(ШаблонРезультатаПроверки, "✅ Верный ответ", Выборка.Текст));
	Иначе
		ЭлементыВопроса.Добавить(СтрШаблон(ШаблонРезультатаПроверки, "❌ Неверный ответ", Выборка.Текст));
	КонецЕсли;	
	
	ТекстВопроса = СтрСоединить(ЭлементыВопроса);
	Если ЭтоФото Тогда
		ИнтеграцияТелеграм.РедактироватьПодпись(Получатель, ИдентификаторСообщения, ТекстВопроса);
	Иначе
		ИнтеграцияТелеграм.РедактироватьСообщение(Получатель, ИдентификаторСообщения, ТекстВопроса);
	КонецЕсли;
	
КонецПроцедуры
	
#КонецОбласти
