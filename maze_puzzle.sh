#!/bin/bash

#########################################################
# Сценарий : Игра - хождение по лабиринту
# Автор : Гордеев Никита, группа 22107
# Дата : 25.05.2022
#########################################################

# ################################# КОНСТАНТЫ #################################

# Текст, который появляется при выигрыше
TEXT_won="
\033[1;34m    ────────╔═══╗──────╔╗────
\033[1;34m    ────────║╔══╝──────║║────
\033[1;34m    ╔═╗─╔══╗║╚══╗╔══╗╔═╝║╔══╗
\033[1;34m    ║╔╗╗║╔╗║║╔═╗║║║═╣║╔╗║║╔╗║
\033[1;34m    ║║║║║╚╝║║╚═╝║║║═╣║╚╝║║╔╗║
\033[1;34m    ╚╝╚╝╚══╝╚═══╝╚══╝╚══╝╚╝╚╝
\033[0m
  "

# Настройки цвета
COLOR_help="\033[0;33m"       # Подсказки, жёлтый текст 
COLOR_labyrinth="\033[0;35m"  # Лабиринт, фиолетовый текст 
COLOR_menuHeader="\033[1;34m" # Заголовки, синий текст, жирное выделение 
COLOR_selection="\033[1;32m"  # Курсор выбора, зелёный текст, жирное выделение
COLOR_reset="\033[0m"         # Все атрибуты по умолчанию


# ################################# ФУНКЦИИ #################################

# Раскраска активного модуля
function build {
  clear
  
  local i=1
  local select=$((SELECT_menu + 1)) 
  
  for item in "${menu[@]}"
  do
    if [ "$select" = $i ]; then
      local color="$COLOR_selection"
    else
      local color="$COLOR_reset"
    fi

    if [ $i = 1 ]; then
      echo -e "\n${COLOR_menuHeader}$item${COLOR_reset}\n"
    elif [ $i == $length ]; then
      echo -e "\n${color}$item${COLOR_reset}"    
      else
        echo -e "${color}$item${COLOR_reset}"
    fi
    
    ((i++))

  done
}

# Определение настроек 
function query_options {
  
  # Запросите некоторые вещи из файла настроек
  OPTIONS_controls="ARROWS"
  
  # Файл карты по умолчанию
  mapfile="default.map"
  
  # Буква ASCII, используемая для обозначения местоположения игроков.
  CHAR_player="O"
  
  # Персонаж, который представляет собой цель, которую необходимо достичь для победы
  CHAR_goal="*"

  # Стандартные клавиши для перемещения
  if [ "$OPTIONS_controls" = "WASD" ]
  then
    KEY_right="d"
    KEY_left="a"
    KEY_down="s"
    KEY_up="w"
  else
    KEY_right="C"
    KEY_left="D"
    KEY_down="B"
    KEY_up="A"
  fi
}

# Выход при получении сигнала прерывания или ручной выход
function exit_program {
  clear
  
  # Сделать курсор нормальным
  exit 0
}

# Главное меню. Пункты меню
function mainMenu {
  menu=(" Добро пожаловать в игру лабиринт" " [*] Играть!" " [*] Выход")
  call=mainMenu_do
}

# Главное меню. Запись выбранного действия
function mainMenu_do {
  case $SELECT_menu in
      1) exitVar="play";;
      2) exit_program;;
  esac 
} 

# Функция менеджера графического интерфейса
function gui {
  while true; do

    # Длина обновления
    length=${#menu[@]}
    
    # "Ремонт" длина var
    max=$((length - 1))

    # ПРОВЕРЬТЕ, НЕ ИЗМЕНИЛОСЬ ЛИ МЕНЮ
    if ! [ "$call_past" = "$call" ]
    then
      
      # Автоматический выбор первой записи
      SELECT_menu=1
      
      # сохраните старый максимум снова для дальнейшего сравнения
      call_past="$call"
    fi

    build
    
    # перехват сигналов прерывания процесса
    trap "if [ "$call" = "mainMenu_do" ]; then exit_program; fi" SIGINT
    read -s -n1 keyInput
    case $keyInput in
        A)
            if ! [ "$SELECT_menu" = "1" ]
            then
              SELECT_menu=$((SELECT_menu - 1))
            fi;;
        B)
            if ! [ "$SELECT_menu" = "$max" ]
            then
              SELECT_menu=$((SELECT_menu + 1))
            fi;;
        "") # ВЫЗВАТЬ СООТВЕТСТВУЮЩИЙ КОД МЕНЮ
            $call

            if [ $exitVar ]
            then
              return
            fi;;
    esac
  done
}

# Сбросить графический интерфейс в главное меню 
function reset_gui {
  # Сбросить выходную переменную!
  exitVar=
  
  # Сбросить, чтобы открыть главное меню
  mainMenu
}

# Вывод лабиринта на экран 
function output {
  clear
  
  # Комментарии по карте лабиринта
  echo -e "${COLOR_help} Текущий лабиринт: $mapfile${COLOR_reset}\n"
  
  local j=0
  
  while [ "$j" -le "$i" ]
  do

    local outputLevel="level$j"
    echo -e "${COLOR_labyrinth}${!outputLevel}"
    ((j++))

  done
  
  # Комментарии по прохождению лабиринта
  echo -e "${COLOR_help} Доберитесь до '$CHAR_goal', чтобы завершить эту карту!${COLOR_reset}"
  echo -e "${COLOR_help} Для выхода зажмите комбинацию клавиш CTRL + C${COLOR_reset}"
}

# Перемещение, границы, победа
function input {
  placeholder=
  case $control in
    $KEY_left)
        local moveToX=$((CHAR_X - 1))
        local moveToY="$CHAR_Y";;
    $KEY_right)
        local moveToX=$((CHAR_X + 1))
        local moveToY="$CHAR_Y";;
    $KEY_down)
        local moveToY=$((CHAR_Y +1 ))
        local moveToX="$CHAR_X";;
    $KEY_up)
        local moveToY=$((CHAR_Y - 1))
        local moveToX="$CHAR_X";;
    *) return;;
  esac

  local nextPosition="array$moveToY[$moveToX]"
  case ${!nextPosition} in
    "$CHAR_goal")
        placeholder="win";;
    " ") # ПРОБЕЛ
        IFS= read "array$CHAR_Y[$CHAR_X]" <<< " "
        IFS= read "array$moveToY[$moveToX]" <<< "$CHAR_player"
        CHAR_X="$moveToX"
        CHAR_Y="$moveToY";;
  esac

}

# Все правильные var для входной функции 
function render_map {
  local j=0

  while [ "$j" -le "$i" ]; do

    local arr="array$j[@]"
    for lvl in "${!arr}"; do
      local tmp+="$lvl"
    done
    
    export "level$j=$tmp"
    local tmp=
    
    ((j++))
  done
}

# Найти расположения игрока 
function locate_player {
  local j=0

  while [ "$j" -le "$i" ]; do

    local arr="array$j[@]"
    local a=0
    for searchPos in "${!arr}"; do
      if [ "$searchPos" = "$CHAR_player" ]; then
        CHAR_X="$a"
        CHAR_Y="$j"
        return
      else
        ((a++))
      fi
    done
    ((j++))
  done

}

# Перевод файла с картой в массивы 
function read_map {
  i=0

  local var=
  while IFS= read -r "var"; do
    IFS=',' read -r -a "array$i" <<< "$var"
    ((i++))
  done < "$mapfile"

}

# Основная функция
function main {
  # 
  if [ -f $HOME/.bashrc ]; then 
    echo "Файл существует!"
  fi

  # Графический интрефейс триггера
  reset_gui
  gui
  
  # После завершения графического интерфейса запустите игру, подготовив карту.
  read_map
  locate_player
  render_map

  # После инициализации делать это бесконечно
  while true; do
    output
    trap "return" SIGINT
    read -s -n1 control
    input
    case $placeholder in
      win)
          echo -e "\n$TEXT_won\n"
          read -r -s -n1
          reset_gui
          return;;
      *) # ИНАЧЕ
          render_map
          output
    esac
  done
}


# ################################# ЗАПУСК ПРОГРАММЫ #################################

# Проверка терминала. Версия BASH
if ! [ "${BASH_VERSION:0:1}" -ge 4 ]; then
  echo -e "\033[0;31m[Ошибка] Чтобы играть в эту игру, вам понадобится как минимум BASH версии 4.0! \033[0m"
  exit 1
fi

# Проверка терминала. Размеры терминала
lines=$(tput lines)
columns=$(tput cols)

if [ "$columns" -lt "80" ] || [ "$lines" -lt "15" ]; then
  echo -e "\033[0;31m[Ошибка] Чтобы играть в эту игру, вам понадобится размер терминала 80x15 строк! \033[0m"
  exit 1
fi

# Проверка терминала. Функции терминала
toCheck=("sed" "find" "grep" "wc")
for check in ${toCheck[@]}
do
  "$check" --help>/dev/null 2>&1 || {
    echo -e "\033[1;31m[Ошибка] Ошибка при поиске команды $check. Невозможно начать! \033[0m";
    exit 1;
  }

done

# ---------------------------------

# Параметры запроса при первом запуске
query_options

# скрыть курсор
tput civis -- invisible

# Запуск главной функции
while true
do
  main
done