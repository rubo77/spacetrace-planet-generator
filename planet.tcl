#! /usr/bin/wish

set fileid [open planet_conf r]
	set numb [read $fileid]
close $fileid

while {$numb < 10000} {
	set numb [expr {$numb +1}]
	set mixer [expr {0.1+(rand()*0.3)}]
	set crater [expr {int(rand()*3)}]
	set fade_number [expr {10+ int(rand()*7)}]	
	set randmap [expr {int(rand()*28)}]
	set randmap_crat [expr {int(rand()*28)}] 
	set randmap_atmos [expr {int(rand()*28)}]
	set dimensiona [expr {(rand()*3.1)}]
	set modus [expr {int(rand()*7)}]
	set dim [expr {0.5+$dimensiona}]
	set pow [expr {0.5+(rand()*1)}]
	set dim_atmos [expr {0.3+$dimensiona}]
        set pow_atmos [expr {0.3+(rand()*1)}]
	set degree [expr {96+(int(rand()*50))}]
	set invert [expr {(rand()*1)}]
	set size [expr {0.06+(rand()*0.15)}]
	puts $numb 
	puts "atmosphere map..."
	catch { exec  ppmforge -clouds -power $pow_atmos -width 600 -height 300 -mesh 1024 -dimension $dim_atmos > atmos.ppm } result
	catch {exec pnmremap -map=/home/susi/allerlei/planets/color_maps/colormap$randmap_atmos.ppm atmos.ppm > atmos_remap.ppm} result
	catch { exec pnmsmooth -size 9 9 atmos_remap.ppm > atmos_cut.ppm } result
	catch { exec pnmcut atmos_cut.ppm -left 30 -right 286 -top 30 -bottom 286 > /home/susi/local/share/xplanet/images/atmos_day_vorlage.ppm } result
	catch { exec pnmcut atmos_cut.ppm -left 287 -right 542 -top 30 -bottom 286 > atmos_dark.ppm } result
	catch { exec ppmbrighten -v -60 atmos_dark.ppm > /home/susi/local/share/xplanet/images/atmos_night_vorlage.ppm } result
	puts "premapping..."
	if { $crater == 1 } {
		puts "crater"
		catch { exec pgmcrater -height 300 -width 600 > crater.pgm } result
		catch { exec pgmtoppm -map color_maps/colormap$randmap_crat.ppm  crater.pgm > crater.ppm  } result 
		puts $result	
		catch { exec  ppmforge -clouds -power $pow -width 600 -height 300 -mesh 1024 -dimension $dim > test.ppm } result
		puts $result
		if { $modus == 1} {
			catch { exec /usr/bin/ppmfade -f test.ppm -l crater.ppm -shift } result
		} elseif { $modus == 5} {
			catch { exec /usr/bin/ppmfade -f test.ppm -l crater.ppm -mix } result
		} elseif { $modus == 2} { 
			catch { exec /usr/bin/ppmfade -f test.ppm -l crater.ppm -spread } result
                } elseif { $modus == 3} { 
                        catch { exec /usr/bin/ppmfade -f test.ppm -l crater.ppm -edge } result
                } elseif { $modus == 4} {
                        catch { exec /usr/bin/ppmfade -f test.ppm -l crater.ppm -bentley } result                		} else {
			catch { exec /usr/bin/ppmfade -f test.ppm -l crater.ppm -relief } result
		}
		puts $result
		catch { exec cp fade.00$fade_number.ppm test.ppm } result
		puts $result
	} else {
		 catch { exec  /usr/bin/ppmforge -clouds -power $pow -width 600 -height 300 -mesh 1024 -dimension $dim > test.ppm } result
	}
	puts $result
	puts "smoothing..."
	catch { exec pnmsmooth -size 5 5 test.ppm > test_smooth.ppm } result
	puts $result
	catch {exec pnmremap -map=/home/susi/allerlei/planets/color_maps/colormap$randmap.ppm test_smooth.ppm > test_remap.ppm } result
	if { $invert < 0.5 } {
		puts "inverted"
		catch { exec pnminvert test_remap.ppm > test_middle.ppm } result
	} else {
		catch { exec cp test_remap.ppm test_middle.ppm } result
	}
	catch { exec pnmcut test_middle.ppm -left 30 -right 286 -top 30 -bottom 286 > /home/susi/local/share/xplanet/images/vorlage_day.ppm } result
	catch { exec pnmcut test_remap.ppm -left 287 -right 542 -top 30 -bottom 286 > test_dark.ppm } result
	catch { exec ppmbrighten -v -70 test_dark.ppm > /home/susi/local/share/xplanet/images/vorlage_night.ppm } result
	puts $result
	puts "planet generating ..."
	catch {exec xplanet -starfreq 0 -date "24 Jun 1999 11:02:17" -image vorlage_day.ppm -night_image vorlage_night.ppm -blend -radius 40 -output planet.ppm } result
	if {$result == ""} {
		puts "ok"
		#catch { exec cp test$numb.jpg /htdocs/spacetrace/entwicklung/planets/ } result
	} else {
		puts $result
	}
	 catch {exec xplanet -starfreq 0 -date "24 Jun 1999 11:02:17" -image atmos_vorlage.ppm -night_image atmos_night_vorlage.ppm -blend -radius 41 -output atmos_ready.ppm } result
        if {$result == ""} {
                puts "ok"
                #catch { exec cp test$numb.jpg /htdocs/spacetrace/entwicklung/planets/ } result
        } else {
                puts $result
        }
	catch { exec ppmmix $mixer planet.ppm atmos_ready.ppm > complete.ppm } result 
	puts "scaling"	
	catch { exec pnmscale $size complete.ppm > planet_s1.ppm } result
	#catch { exec pnmscale 0.17 complete.ppm > planet_s2.ppm } result
	#catch { exec pnmscale 0.14 complete.ppm > planet_s3.ppm } result
	#catch { exec pnmscale 0.11 complete.ppm > planet_s4.ppm } result
	#catch { exec pnmscale 0.09 complete.ppm > planet_s5.ppm } result
	#catch { exec pnmscale 0.07 complete.ppm > planet_s6.ppm } result
	#catch { exec pnmscale 0.06 complete.ppm > planet_s7.ppm } result

	catch { exec ppmtojpeg planet_s1.ppm > planet_s1_$numb.jpg } result
	#catch { exec ppmtojpeg planet_s2.ppm > planet_s2_$numb.jpg } result
	#catch { exec ppmtojpeg planet_s3.ppm  > planet_s3_$numb.jpg } result
	#catch { exec ppmtojpeg planet_s4.ppm  > planet_s4_$numb.jpg } result
	#catch { exec ppmtojpeg planet_s5.ppm  > planet_s5_$numb.jpg } result
	#catch { exec ppmtojpeg planet_s6.ppm  > planet_s6_$numb.jpg } result
        #catch { exec ppmtojpeg planet_s7.ppm  > planet_s7_$numb.jpg } result
	puts ""	
	set fileid [open planet_conf w]
 		puts $fileid $numb
 	close $fileid
	#catch {exec display test$numb.jpg } result
}

