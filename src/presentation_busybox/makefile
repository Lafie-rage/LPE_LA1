all : myblox liens

liens :
	ln -s mybox mycp; ln -s main.c myps

myblox : affiche_nom_appel.c
	gcc $^ -o $@
