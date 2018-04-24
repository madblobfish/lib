function somethingwithpackages
	# finds packages without upstream (ppa or sources.list entry)
	# obfuscated because it was written like that
	for i in (dpkg -l | grep '^i' | awk '{ print $2,$3 }');
		set b (echo $i | sed 's/ /\n/');
		if test (apt-cache policy $b[1] | pcregrep -M (echo $b[2]| sed 's/[]\.|$(){}?+*^]/\\\&/g')'(.+\n {8})+' | wc -l) -le "2";
			echo "AH "$b[1]" "$b[2];
		end;
	end
end

# basch
# for i in $(dpkg -l | grep '^i' | awk '{ print $2 "@" $3 }'); do v=$(echo $i | sed -re 's/.*@([^@]+)$/\1/'); p=$(echo $i | sed -re 's/^([^@]+)@.*/\1/'); if test $(apt-cache policy $p | pcregrep -M "$(echo $v| sed 's/[]\.|$(){}?+*^]/\\&/g')(.+\n {8})+" | wc -l) -le "2"; then echo "AH $p $v"; fi; done
