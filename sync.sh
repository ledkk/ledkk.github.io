cur_ip="`ifconfig | grep wg0`"
if [ -z "$cur_ip" ]; then
	rsync -vrtaz rsync://johnzb@10.0.8.1/note ./
else 
	rsync -vrtaz rsync://johnzb@10.0.8.10/note ./
fi


