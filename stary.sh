#!/bin/bash

g_InFpsGiven=0
g_FormatDetected=0
g_ProcTmpFile="/tmp/subotage_$$.tmp"

################################################################################
########################## format detection routines ###########################
################################################################################
# each detection function should return a string delimited by spaces containing:
# - format name (as in g_FileFormats table) or "not detedted" string
#       if file has not been identified
# - line in file on which a valid format line has been found (starting from 1)
# - format specific data
################################################################################

# fab format detection routine
function f_is_fab_format
{
    local max_attempts=8
    local attempts=$max_attempts
    local match="not detected"
    local first_line=1
	local cnti='empty'
    
    while read file_line; do
        if [ "$attempts" -eq 0 ]; then
            break
        fi
        
        first_line=$(( max_attempts - attempts + 1))  
        cnti=$(echo $file_line | sed -r 's/^[0-9]+ : [0-9]+:[0-9]+:[0-9]+:[0-9]+[ ]+[0-9]+:[0-9]+:[0-9]+:[0-9]+[\r\n]*$/success/')
        
        if [ "$cnti" = "success" ]; then
            match="fab $first_line"
            break
        fi  
        
        attempts=$(( attempts - 1 ))       
    done < "$1"
    echo $match
}

# subviewer format detection routine
function f_is_subviewer_format
{
    local max_attempts=16
    local attempts=$max_attempts
    local match="not detected"
    local first_line=0
    
    local header_found=0
	local header_line=''

    while read file_line; do
        if [ "$attempts" -eq 0 ]; then
            break
        fi
        
        first_line=$(( first_line + 1 ))
        
        if [ "$header_found" -eq 1 ]; then
            match_line=$(echo $file_line | sed -r 's/^[0-9]+:[0-9]+:[0-9]+:[0-9]+,[0-9]+:[0-9]+:[0-9]+:[0-9]+[ \r]*$/success/')
            
            if [ "$match_line" = "success" ]; then
                first_line=$(( first_line - 1 ))
                match="subviewer $first_line"
                break
            fi          
        fi

		header_line=$(echo $file_line | grep "\[INFORMATION\]")
                
        if [ -n "$header_line" ]; then
            header_found=1
            continue
        fi
                
        attempts=$(( attempts - 1 ))       
    done < "$1"
        
    echo $match 
}


# tmplayer format detection routine
function f_is_tmplayer_format
{
    local max_attempts=3
    local attempts=$max_attempts
    local match="not detected"
    local first_line=1
    
    local multiline="no"
    local hour_digits=2
    local delimiter=":"
    
    while read file_line; do
        if [ "$attempts" -eq 0 ]; then
            break
        fi
        
        first_line=$(( max_attempts - attempts + 1 ))
        
        # the check itself
        match_value=$(echo "$file_line" | sed -r 's/^[0-9]+:[0-9]+:[0-9]+/success/')
        
        # tmplayer format detected. Get more details
		local det=$(echo "$match_value" | grep "success")
        if [ -n "$det" ]; then
                
            hour_digits=$(echo "$file_line" | awk 'BEGIN { FS=":"; } { printf ("%d", length($1)); }')
            mline=$(echo "$file_line" | sed -r 's/^[0-9]+:[0-9]+:[0-9]+,[0-9]+/success/')

			local mline_test=$(echo "$mline" | grep "success")
            
            if [ -n "$mline_test" ]; then
                multiline="yes"
                
                # determine the time, text delimiter type           
                delimiter=$(echo "$mline" | sed 's/^success\(.\).*/\1/')
            else
                delimiter=$(echo "$match_value" | sed 's/^success\(.\).*/\1/')
            fi
            
            match="tmplayer $first_line $hour_digits $multiline [$delimiter]"
            break
        fi 

        attempts=$(( attempts - 1 ))       
    done < "$1"
        
    echo $match
}

# microdvd format detection routine
function f_is_microdvd_format
{
    local max_attempts=3
    local attempts=$max_attempts
    local match="not detected"
    local first_line=1
	local fps=''

    while read file_line; do
        if [ "$attempts" -eq 0 ]; then
            break
        fi

        first_line=$(( max_attempts - attempts + 1 ))
        
        match_value=$(echo $file_line | cut -d '}' -f -2 | sed 's/^{[0-9]*}{[0-9]*$/success/')      

        # it is microdvd format, try to determine the frame rate from the first line
        if [ "$match_value" = "success" ]; then
            match="microdvd $first_line"
            fps_info=$(head -n 1 "$1" | cut -d '}' -f 3-)
			fps=0

			local fps_value=$(echo "$fps_info" | awk '/^[0-9]+[\.0-9]*[\r\n]*$/')
            if [ -n "$fps_value" ]; then
                fps=$(echo $fps_info | tr -d '\r\n')
            fi
            break   
        fi
        
        attempts=$(( attempts - 1 ))       
    done < "$1"

	if [ "$match" != "not detected"  ]; then
		echo "$match $fps"
	else
		echo "$match"
	fi
}

# mpl2 format detection routine
function f_is_mpl2_format
{
    local max_attempts=3
    local attempts=$max_attempts
    local match="not detected"
    local first_line=1    

    while read file_line; do
        if [ "$attempts" -eq 0 ]; then
            break
        fi
        
        first_line=$(( max_attempts - attempts + 1))
        match_value=$(echo $file_line | cut -d ']' -f -2 | sed 's/^\[[0-9]*\]\[[0-9]*$/success/')       

        # mpl2 format detected
        if [ "$match_value" = "success" ]; then
            match="mpl2 $first_line"
            break   
        fi
        
        attempts=$(( attempts - 1 ))       
    done < "$1"

    echo $match
}


# subrip format detection routine
function f_is_subrip_format
{
    local match="not detected"
    local max_attempts=8
    local attempts=$max_attempts
    local counter_type="not found"
    local first_line=1

    while read file_line; do
        if [ "$attempts" -eq 0 ]; then
            break
        fi

        if [ "$counter_type" = "not found" ]; then      
            cntn=$(echo "$file_line" | awk '/^[0-9]+[\r\n]*$/')
            first_line=$(( max_attempts - attempts + 1 ))

            if [ -n "$cntn" ]; then
                counter_type="newline"              
                continue
            fi
            
            cnti=$(echo "$file_line" | sed -r 's/^[0-9]+ [0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+[\r\n]*$/success/')

            if [ "$cnti" = "success" ]; then
                counter_type="inline"
                match="subrip $first_line inline"
                break
            fi
        elif [ "$counter_type" = "newline" ]; then
            
            time_check=$(echo "$file_line" | sed -r 's/^[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+[\r\n]*$/success/')

            if [ "$time_check" = "success" ]; then
                match="subrip $first_line newline"
                break
            else
                counter_type="not found"
            fi
        fi
                    
        attempts=$(( attempts - 1 ))       
    done < "$1" 
    
    echo "$match" 
}

###############################################################################
########################## format detection routines ##########################
###############################################################################




###############################################################################
############################ format read routines #############################
###############################################################################
# Input parameters
# - filename to process
#
# Output: 
# - should be written in universal format. Line format
# - subtitle line number
# - time type: ( "hms", "hmsms", "secs" )
# - start time
# - stop time
# - line itself
#
# Return Value
# - 0 - when file is processed and all the data is converted to 
#             universal format present in /tmp file
###############################################################################

# subviewer -> uni format converter
function f_read_subviewer_format
{
    echo "secs" > "$g_ProcTmpFile"

    tail -n +"$2" "$1" | tr -d '\r' | 
    awk "BEGIN { 
		FS=\"\n\"; RS=\"\"; linecc=1; 
		};
        {   split(\$1, start, \",\");
            split(start[1], tm_start, \":\");
            split(start[2], tm_stop, \":\");
            time_start=(tm_start[1]*3600 + tm_start[2]*60 + tm_start[3] + tm_start[4]/100)
            time_stop=(tm_stop[1]*3600 + tm_stop[2]*60 + tm_stop[3] + tm_stop[4]/100)       
            printf(\"%d %s %s \", linecc, time_start, time_stop);           
            for (i=2; i<=NF; i++) {
                if (i>2) printf(\"|\");
                printf(\"%s\", \$i);                        
            }
            printf(\"\n\");
            linecc=linecc + 1;
        }" >> "$g_ProcTmpFile"
        
    echo 0  
}

# tmplayer -> uni format converter
function f_read_tmplayer_format
{
    multiline="no"
    hour_digits=2
    delimiter=":"
    
    # format information based on autodetection
    if [ "${#g_InputFormatData[*]}" -gt 3 ]; then
        
        hour_digits="${g_InputFormatData[2]}"
        multiline="${g_InputFormatData[3]}"
        delimiter="$(echo ${g_InputFormatData[4]} | tr -d '[]')"
    fi
    
    echo "hms" > $g_ProcTmpFile
    
    if [ "$multiline" = "no" ]; then
    
        if [ "$delimiter" = ":" ]; then
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { 
						FS=\"$delimiter\";
						line_processed = 1;
					}; 
					/^ *$/ {
						next;
					};
					NF { 
						x=(\$1*3600+\$2*60+\$3 + ($g_LastingTime/1000));
						printf(\"%d %02d:%02d:%02d %02d:%02d:%02d \", line_processed++, 
							\$1,\$2,\$3,
							(x/3600), ((x/60)%60), (x%60));

						for (i=4; i<=NF; i++) 
							printf(\"%s\", \$i);
						printf \"\n\"; 
					}" >> "$g_ProcTmpFile"      
        else
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { FS=\"$delimiter\" }; 
                {                   
                    split(\$1, st, \":\");
                    x=((st[1]*3600)+(st[2]*60)+st[3]) + ($g_LastingTime/1000);
                    printf(\"%d %s %02d:%02d:%02d \", NR, 
                    \$1,
                    (x/3600), ((x/60)%60), (x%60));
                    for (i=2; i<=NF; i++) printf(\"%s\", \$i);
                    printf \"\n\"; 
                }" >> "$g_ProcTmpFile"                  
        fi  
    else
        if [ "$delimiter" = ":" ]; then
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { FS=\"$delimiter\"; xprev=0; linecc=1; }; 
                {                   
                    split(\$3, st, \",\");
                    xc=(\$1*3600+\$2*60+st[1]);
                    xe=xc+($g_LastingTime/1000);
                    if (xc == xprev && NR>1) {
                        printf(\"|\");                      
                    } else
                    {
                        if (NR>1) {
                            printf \"\n\";
                            linecc=linecc+1;
                        }                                               
                        printf(\"%d %02d:%02d:%02d %02d:%02d:%02d \", linecc, 
                            \$1,\$2,\$3,
                            (xe/3600), ((xe/60)%60), (xe%60));
                    }                       
                    for (i=4; i<=NF; i++) printf(\"%s\", \$i);
                    xprev=xc;           
                }" >> "$g_ProcTmpFile"
        else
            tail -n +"$2" "$1" | tr -d '\r' | 
                awk "BEGIN { FS=\"$delimiter\"; xprev=0; linecc=1; }; 
                {                   
                    split(\$1, st, \"[:,]\");
                    xc=((st[1]*3600)+(st[2]*60)+st[3]);
                    xe=xc+($g_LastingTime/1000);                    
                    if (xc == xprev && NR>1) {
                        printf(\"|\");                      
                    } else
                    {
                        if (NR>1) {
                            printf \"\n\";
                            linecc=linecc+1;
                        }                                               
                        printf(\"%d %02d:%02d:%02d %02d:%02d:%02d \", linecc, 
                            (xc/3600), ((xc/60)%60), (xc%60),
                            (xe/3600), ((xe/60)%60), (xe%60));                       
                    }                       
                    for (i=2; i<=NF; i++) printf(\"%s\", \$i);
                    xprev=xc;           
                }" >> "$g_ProcTmpFile"
        fi
    fi
    
    echo 0
}

# microdvd -> uni format converter
function f_read_microdvd_format
{   
    echo "secs" > "$g_ProcTmpFile"
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { 
				FS=\"[{}]+\";
				txt_begin = 0;
				line_processed = 1;
			}; 
			/^ *$/ {
				next;
			}
			{
				fstart=\$2;
				if (\$3+0) {
					txt_begin=4;
					fend=\$3;
				}
				else {
					txt_begin=3;
					fend = \$2 + 5*$g_InputFrameRate;
				}

			   	printf \"%s %s %s \", line_processed++, 
					(fstart/$g_InputFrameRate), (fend/$g_InputFrameRate);

            	for (i=txt_begin; i<=NF; i++) 
					printf(\"%s\", \$i);
				printf \"\n\"; 
			}" >> "$g_ProcTmpFile"
    echo 0
}

# mpl2 -> uni format converter
function f_read_mpl2_format
{
    echo "secs" > "$g_ProcTmpFile"
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { 
				FS=\"[][]+\";
				line_processed = 1;
			}; 
			/^ *$/ {
				next;
			}
			NF { 
				printf \"%s %s %s \", line_processed++, (\$2/10), (\$3/10);
				for (i=4; i<=NF; i++) printf(\"%s\", \$i);
				printf \"\n\"; 
			}" >> "$g_ProcTmpFile"
    echo 0
}

# subrip -> uni format converter
function f_read_subrip_format
{
    echo "hmsms" > "$g_ProcTmpFile"
    
    if [ "$3" = "inline" ]; then
    
        tail -n +"$2" "$1" | tr -d '\r' | 
            awk "BEGIN { 
					FS=\"\n\"; 
					RS=\"\"; 
				};
                NF {  
					gsub(\",\", \".\", \$1);
                    printf(\"%s \", \$1);
                    for (i=2; i<=NF; i++) {
                        if (i>2) printf(\"|\");
                        printf(\"%s\", \$i);                        
                    }
                    printf(\"\n\");
                }" | sed 's/--> //' >> "$g_ProcTmpFile"
                
    else
        # assume newline style      
        tail -n +"$2" "$1" | tr -d '\r' | 
            awk "BEGIN { FS=\"\n\"; RS=\"\"; };
                {   gsub(\",\", \".\", \$2);
                    printf(\"%s %s \", \$1, \$2);
                    for (i=3; i<=NF; i++) {
                        if (i>3) printf(\"|\");
                        printf(\"%s\", \$i);                        
                    }
                    printf(\"\n\");
                }" | sed 's/--> //' >> "$g_ProcTmpFile"                 
    fi
    
    echo 0
}


# fab -> uni format converter
function f_read_fab_format
{
    echo "hmsms" > "$g_ProcTmpFile"
    
    tail -n +"$2" "$1" | tr -d '\r' | 
        awk "BEGIN { FS=\"\n\"; RS=\"\"; };
            {   
                split(\$1,tm, \":\");
                split(tm[5],tm2, \" \");
                printf(\"%d %02d:%02d:%02d.%02d %02d:%02d:%02d.%02d \", 
                    tm[1], tm[2], tm[3], tm[4], tm2[1],
                    tm2[2], tm[6], tm[7], tm[8]);
                                        
                for (i=2; i<=NF; i++) {
                    if (i>2) printf(\"|\");
                    printf(\"%s\", \$i);                        
                }
                printf(\"\n\");
            }" >> "$g_ProcTmpFile"
                
    echo 0
}

###############################################################################
############################ format read routines #############################
###############################################################################






###############################################################################
############################ format write routines ############################
###############################################################################

# uni -> microdvd format converter
function f_write_microdvd_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs") 
    tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
    awk "{ printf \"{%d}{%d}\", (\$2*$g_OutputFrameRate),(\$3*$g_OutputFrameRate);
            for (i=4; i<=NF; i++) printf(\"%s \", \$i); \
            printf \"\n\" }" > "$1"
    ;;
    
    "hmsms" | "hms")
    tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");                    
            printf(\"{%d}{%d}\", 
             ((start[1]*3600 + start[2]*60 + start[3])*$g_OutputFrameRate),
             ((stop[1]*3600 + stop[2]*60 + stop[3])*$g_OutputFrameRate));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\" }" > "$1" 
    ;;
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


# uni -> tmplayer format converter
function f_write_tmplayer_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs")
        tail -n +2  "$g_ProcTmpFile" | tr -d '\r' |
        awk "{ 
				printf(\"%02d:%02d:%02d:\", 
					(\$2/3600),((\$2/60)%60),(\$2%60));
				for (i=4; i<=NF; i++) printf(\"%s \", \$i);
				printf \"\n\";
			}" > "$1" 
    ;;
    
    "hms" | "hmsms")
        tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
        awk "{ printf (\"%s:\", 
                substr(\$2, 0, index(\$2, \".\")));
                for (i=4; i<=NF; i++) printf(\"%s \", \$i); \
                printf \"\n\" }" > "$1" 
    ;;
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


# uni -> subviewer format converter
function f_write_subviewer_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    echo    "[INFORMATION]" > "$1"  
    echo    "[TITLE] none" >> "$1"  
    echo    "[AUTHOR] none" >> "$1" 
    echo    "[SOURCE]" >> "$1"  
    echo    "[FILEPATH]Media" >> "$1"
    echo    "[DELAY]0" >> "$1"
    echo    "[COMMENT] Created using subotage - universal subtitle converter for bash" >> "$1"
    echo    "[END INFORMATION]" >> "$1" 
    echo    "[SUBTITLE]" >> "$1"
    echo    "[COLF]&HFFFFFF,[STYLE]bd,[SIZE]18,[FONT]Arial" >> "$1"
    
    
    case $time_type in
    "secs")
        tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
            awk "{ 
                    printf (\"%02d:%02d:%02d:%02d,%02d:%02d:%02d:%02d\n\",
                        (\$2/3600),((\$2/60)%60),(\$2%60),                   
                        int((\$2 - int(\$2))*100),
                        (\$3/3600),((\$3/60)%60),(\$3%60),
                        int((\$3 - int(\$3))*100));
                        for (i=4; i<=NF; i++) printf(\"%s \", \$i); 
                        printf (\"\n\n\");
             }" | tr '|' '\n' >> "$1"
    ;;
    
    "hmsms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%02d:%02d:%02d:%02d,%02d:%02d:%02d:%02d\n\",
                (start[1]),(start[2]),(start[3]),
                int((start[3] - int(start[3]))*100),
                (stop[1]),(stop[2]),(stop[3]),
                int((stop[3] - int(stop[3]))*100));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' >> "$1"
    ;;  

    "hms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%02d:%02d:%02d:%02d,%02d:%02d:%02d:%02d\n\",
                (start[1]),(start[2]),(start[3]),
                (0),
                (stop[1]),(stop[2]),(stop[3]),
                (0));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' >> "$1"
    ;;
    
    *)
    echo 1
    return
    ;;
    esac
        
    echo 0
}


# uni -> mpl2 format converter
function f_write_mpl2_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs") 
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{ printf \"[%d][%d]\", (\$2*10),(\$3*10);
            for (i=4; i<=NF; i++) printf(\"%s \", \$i); \
            printf \"\n\" }" > "$1"
    ;;
    
    "hmsms" | "hms")
    tail -n +2  "$g_ProcTmpFile" |  tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");                    
            printf(\"[%d][%d]\", 
             ((start[1]*3600 + start[2]*60 + start[3])*10),
             ((stop[1]*3600 + stop[2]*60 + stop[3])*10));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\" }" > "$1"     
    ;;
        
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}

# uni -> subrip format converter
function f_write_subrip_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{ 
            printf(\"%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n\",
            \$1, (\$2/3600),((\$2/60)%60),(\$2%60),
            int((\$2 - int(\$2))*1000),         
            (\$3/3600),((\$3/60)%60),(\$3%60),
            int((\$3 - int(\$3))*1000));            
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf (\"\n\n\");
         }" | tr '|' '\n' > "$1"
    ;;
    
    "hmsms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                int((start[3] - int(start[3]))*1000),
                (stop[1]),(stop[2]),(stop[3]),
                int((stop[3] - int(stop[3]))*1000));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  

    "hms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                (0),
                (stop[1]),(stop[2]),(stop[3]),
                (0));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


# uni -> fab format converter
function f_write_fab_format
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
    
    case $time_type in
    "secs")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{ 
            printf(\"%04d : %02d:%02d:%02d:%02d  %02d:%02d:%02d:%02d\n\",
            \$1, (\$2/3600),((\$2/60)%60),(\$2%60),
            int((\$2 - int(\$2))*100),          
            (\$3/3600),((\$3/60)%60),(\$3%60),
            int((\$3 - int(\$3))*100));         
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf (\"\n\n\");
         }" | tr '|' '\n' > "$1"
    ;;
    
    "hmsms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%04d : %02d:%02d:%02d:%02d  %02d:%02d:%02d:%02d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                int((start[3] - int(start[3]))*100),
                (stop[1]),(stop[2]),(stop[3]),
                int((stop[3] - int(stop[3]))*100));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  

    "hms")
    tail -n +2 "$g_ProcTmpFile" |   tr -d '\r' |
    awk "{  split(\$2, start, \":\"); 
            split(\$3, stop, \":\");    
            printf(\"%04d : %02d:%02d:%02d:%02d  %02d:%02d:%02d:%02d\n\",
                \$1, (start[1]),(start[2]),(start[3]),
                (0),
                (stop[1]),(stop[2]),(stop[3]),
                (0));
            for (i=4; i<=NF; i++) printf(\"%s \", \$i);
            printf \"\n\n\" }" | tr '|' '\n' > "$1"
    ;;  
    
    *)
    echo 1
    return
    ;;
    esac
    
    echo 0
}


###############################################################################
############################ format write routines ############################
###############################################################################

###############################################################################
############################### common routines ###############################
###############################################################################

# @brief try to determine the input file format
function f_guess_format
{
    local lines=$(cat "$1" 2> /dev/null | count_lines)
    if [ "$lines" -eq 0 ]; then
        f_print_error "Input file has zero lines inside"
        exit -1
    fi
    
    local detected_format="not detected"
    
    for a in "${g_FileFormats[@]}"; do
        function_name="f_is_${a}_format"
        detected_format=$($function_name "$1")
        [ "$detected_format" != "not detected" ] && break
    done

    echo $detected_format
}

function f_correct_overlaps
{
    time_type=$(head -n 1 "$g_ProcTmpFile")
	num_lines=$(( $(cat "$g_ProcTmpFile" | count_lines) - 1))
    
	# now I need to rewrite the univeral file once again
    case $time_type in
    "secs")
		# recreate the secs header
		echo "secs" > "${g_ProcTmpFile}_2"
        tail -n +2  "$g_ProcTmpFile" | tr -d '\r' |
		awk "BEGIN {
				previous_end = 0;			
				cntr = 0;
				line_cnt = 0;
				
			 }
			 {				
				 lines[cntr,0] = NF;
				 for (i=1; i<=NF; i++) lines[cntr,i] = \$i;

				 if (cntr == 0) {
					 if ((lines[1,3]+0) > (lines[0,2]+0)) lines[1,3] = lines[0,2];
				 }
				 else {
					 if ((lines[0,3]+0) > (lines[1,2]+0)) lines[0,3] = lines[1,2];
				 }
				 
				 do {
					 line_cnt++;
					 cntr = (cntr + 1) % 2;

					 if ((line_cnt >= 2 || line_cnt == $num_lines) && lines[cntr,0]>0) {
						 printf \"%s %s %s \", lines[cntr,1], lines[cntr,2], lines[cntr,3];
						 for (i=4; i<=lines[cntr,0]; i++) printf(\"%s \", lines[cntr,i]);
						 printf \"\n\"; 
					 }
				 } while (line_cnt == $num_lines)
			}" >> "${g_ProcTmpFile}_2"

		# overwrite the original file
		mv "${g_ProcTmpFile}_2" "${g_ProcTmpFile}"
	;;
    
    "hms" | "hmsms")
# it's very unlikely that a file in this format will have any overlapping time stamps
# for the moment this is to be implemented
	return
    ;;
    
    *)
    return
    ;;
    esac	
}

###############################################################################
############################### common routines ###############################
###############################################################################



###############################################################################
############################## parameter parsing ##############################
###############################################################################

format verification
        if_valid=0
        for i in "${g_FileFormats[@]}"; do      
            if [ "$i" == "$1" ]; then
                if_valid=1
                break
            fi      
        done
        
        if [ "$if_valid" -eq 0 ]; then
            f_print_error "Specified input format is not valid: [$1]"
            exit -1
        fi      

fps verification
        # check if fps is integer or float
        if [ -n "$(echo "$1" | tr -d '[\n\.0-9]')" ]; then
            f_print_error "Framerate is not in an acceptable number format [$1]"
            exit -1
        else
            g_InputFrameRate="$1"
        fi      


# filenames validation
if [ "$g_InputFile" = "none" ] || [ "$g_OutputFile" = "none" ]; then
    f_print_error "Input/Output file not specified !!!"
    exit -1
fi

# handle the input file format
if [ "$g_InputFormat" = "none" ]; then
    g_DetectedFormat=$(f_guess_format "$g_InputFile")

    if [ "$g_DetectedFormat" = "not detected" ]; then
        f_print_error "Invalid Input File Format!\nSpecify input format manually to override autodetection."
        exit -1
    fi
    
    g_InputFormat="$g_DetectedFormat"
    g_InputFormatData=( $(echo $g_InputFormat) )
    g_FormatDetected=1
else
    g_InputFormatData=( "$g_InputFormat" 1 0 )
fi

# some info
f_echo "Input File Format Detected: [${g_InputFormatData[@]}]"
f_echo "Actual Data found at line: [${g_InputFormatData[1]}]"
f_echo "Output Format Selected: [$g_OutputFormat]"


# format specific data manipulation operations
# executed only if format detection was performed
if [ "$g_FormatDetected" -eq 1 ]; then  
    case "${g_InputFormatData[0]}" in
        
        "microdvd")
        if [ "$g_InFpsGiven" -eq 0 ]; then

            tmpFps=${g_InputFormatData[$(( ${#g_InputFormatData[@]} - 1 ))]}                        
            if [ -n "$tmpFps" ] && [ "$tmpFps" != "0" ]; then
                g_InputFrameRate=$tmpFps
            fi
        fi
        
        f_echo "Input FPS: [$g_InputFrameRate]"       
        ;;
        
        *)
        ;;
    esac
fi

# the same for output format
case "$g_OutputFormat" in   
    "microdvd") 
    f_echo "Output FPS: [$g_OutputFrameRate]"     
    ;;
    
    *)
    ;;
esac


# check if conversion is really needed
if [ "${g_InputFormatData[0]}" = "$g_OutputFormat" ]; then

    # additional format specific checks
    case "${g_InputFormatData[0]}" in
    
        "microdvd")
            if [ "${g_InputFrameRate:0:5}" = "${g_OutputFrameRate:0:5}" ]; then
                f_print_warning "Convertion aborted. In Fps == Out Fps == [$g_InputFrameRate]"
				# RET_NOACT
                exit 251
            fi
        ;;
    
        *)
        f_print_warning "No convertion is needed input format == output format"
		# RET_NOACT
		exit 251
        ;;
    esac
fi

###############################################################################
############################## parameter parsing ##############################
###############################################################################



###############################################################################
############################## actual convertion ##############################
###############################################################################

g_Reader="f_read_${g_InputFormatData[0]}_format"
g_Writer="f_write_${g_OutputFormat}_format"

echo > "$g_ProcTmpFile"

# input file, first valid line, format specific data
status=$($g_Reader "$g_InputFile" "${g_InputFormatData[1]}" "${g_InputFormatData[2]}")

if [ "$status" -ne 0 ]; then
    f_print_error "Reading error. Error code: [$status]"
    exit -1
else
	f_correct_overlaps
    status=$($g_Writer "$g_OutputFile")
    
    if [ "$status" -ne 0 ]; then
        f_print_error "Writing error. Error code: [$status]"
        exit -1
    fi
fi
    
# remove the temporary processing file
rm -rf "$g_ProcTmpFile"
echo "Done"

###############################################################################
############################## actual convertion ##############################
###############################################################################
# EOF
