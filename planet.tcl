#! /usr/bin/wish

# installed xplanet via
# $ sudo apt install xplanet xplanet-images pysatellites
# Then copy the needed images for the planets with:
# $ cp /usr/share/pysatellites/images/* ~/.xplanet/images/
# 
#
# for xplanet see http://xplanet.sourceforge.net/README.config
# and http://xplanet.sourceforge.net/README
# defaults are defined in /usr/share/xplanet/config/default
#
# maps from https://github.com/Zarkonnen/GenGen copied with
# m=0; for i in color_maps/gengen/*; do cp "$i" color_maps/colormap$m.jpg; m=$(( $m + 1 )); done

# to start again with the first planet reset the counter with
# echo '0' > ./configs/planet_progress_count

exec mkdir -p temp planets
set fileid [open configs/planet_progress_count r]
	set numb [read $fileid]
close $fileid

while {$numb < 999} {
	set numb [expr {$numb +1}]
	
	# how to blend together planet with atmosphere
	set mixer [expr {0.1+(rand()*0.3)}]
	
	# if crater map is used or not
	set crater [expr {int(rand()*3)}]
	set crater_fade_number [expr {10+ int(rand()*7)}]
	set crater_distort_mode [expr {int(rand()*7)}]
	
	# which color_map number is used for planet, crater and atmosphere
	set randmap [expr {int(rand()*28)}]
	set randmap_crat [expr {int(rand()*28)}] 
	set randmap_atmos [expr {int(rand()*28)}]
	
	# atmosphere
	set dimensiona [expr {(rand()*3.1)}]
	# -dimension Sets the fractal dimension, which may be any floating point value between 0 and 3.  Higher fractal dimensions create more ``chaotic'' images
	set dim_map [expr {0.5+$dimensiona}]
	set dim_atmos [expr {0.3+$dimensiona}]
	# -power is used to scale elevations synthesised from the FFT
	set pow_map [expr {0.5+(rand()*1)}]
	set pow_atmos [expr {0.3+(rand()*1)}]
	
	# 50% chance to color-invert the whole map
	set invert_map [expr {(rand()*1)}]
	
	# final output of the planet PNG
	set output_size [expr {((0.2+rand()*0.1)*5)}]
	
	# TODO: use $xplanet_options 
	set xplanet_options "-body mars -date \"24 Jun 2020 13:02:17\" -radius 40 -num_times 1 -origin phobos -localtime 9 -north body -config"
	
	puts "---------- $numb ----------------"
	puts "randmap: $randmap; randmap_atmos: $randmap_atmos;"
	puts "crater: $crater; crater_fade_number: $crater_fade_number; crater_distort_mode: $crater_distort_mode;"
	puts "randmap: $randmap; randmap_crat: $randmap_crat; randmap_atmos: $randmap_atmos;"
	puts "dimensiona: $dimensiona; dim_map: $dim_map; dim_atmos: $dim_atmos; pow_map: $pow_map; pow_atmos: $pow_atmos; invert_map: $invert_map; output_size: $output_size;"
	
	puts ""
	puts "########## 1. atmosphere map..."
	# ppmforge - generates two varieties of pictures: planets and clouds
	# pnmremap - replace colors in a PPM image with colors from another set
	# pgmtoppm - colorize a portable graymap into a portable pixmap
	# pgmcrater - create cratered terrain by fractal forgery
	catch { exec ppmforge -clouds -power $pow_atmos -width 600 -height 300 -mesh 1024 -dimension $dim_atmos > temp/1-atmos.ppm } result
	#puts "creating temp/colormap$randmap_atmos.ppm from color_maps/colormap$randmap_atmos.jpg"
	catch { exec convert color_maps/colormap$randmap_atmos.jpg -compress none temp/colormap$randmap_atmos.ppm } result
	if {$result != ""} { puts $result }
	catch { exec pnmremap -map=temp/colormap$randmap_atmos.ppm temp/1-atmos.ppm > temp/2-atmos_color_remap.ppm } result
	catch { exec pnmsmooth -size 9 9 temp/2-atmos_color_remap.ppm > temp/3-atmos_cut.ppm } result
	#catch { exec pnmcut temp/3-atmos_cut.ppm -left 30 -right 286 -top 30 -bottom 286 > temp/4-atmos_template.ppm } result
	catch { exec cp temp/3-atmos_cut.ppm temp/4-atmos_template.ppm } result
	#catch { exec pnmcut temp/3-atmos_cut.ppm -left 287 -right 542 -top 30 -bottom 286 > temp/5-atmos_dark.ppm } result
	catch { exec cp temp/3-atmos_cut.ppm temp/5-atmos_dark.ppm } result
	catch { exec ppmbrighten -v -60 temp/5-atmos_dark.ppm > temp/6-atmos_night_template.ppm } result
	
	puts ""
	puts "########## 2. premapping..."
	if { $crater == 1 } {
		puts "crater"
		catch { exec pgmcrater -height 300 -width 600 > temp/7-crater.pgm } result
		catch { exec convert color_maps/colormap$randmap_crat.jpg -compress none temp/colormap$randmap_crat.ppm } result
		if {$result != ""} { puts $result }
		#puts "creating temp/8-crater.ppm from temp/colormap$randmap_crat.ppm"
		catch { exec pgmtoppm -map temp/colormap$randmap_crat.ppm  temp/7-crater.pgm > temp/8-crater.ppm  } result 
		puts $result
		puts "generate temp/9-map.ppm"
		catch { exec ppmforge -clouds -power $pow_map -width 600 -height 300 -mesh 1024 -dimension $dim_map > temp/9-map.ppm } result
		puts $result
		puts "mode $crater_distort_mode"
		# ppmfade - generate a transition between two image files using special effects
		if { $crater_distort_mode == 1} {
			# ppmshift - shift lines of a portable pixmap left or right by a random amount
				# shift
			catch { exec /usr/bin/ppmfade -base temp/crater_transition -f temp/9-map.ppm -l temp/8-crater.ppm -shift } result
		} elseif { $crater_distort_mode == 5} {
			# ppmmix - blend together two portable pixmaps
			catch { exec /usr/bin/ppmfade -base temp/crater_transition -f temp/9-map.ppm -l temp/8-crater.ppm -mix } result
		} elseif { $crater_distort_mode == 2} { 
			# ppmspread - displace a portable pixmap's pixels by a random amount
			catch { exec /usr/bin/ppmfade -base temp/crater_transition -f temp/9-map.ppm -l temp/8-crater.ppm -spread } result
		} elseif { $crater_distort_mode == 3} { 
			# -edge  The first image is faded to an edge detected version of the first image.
			# This is then faded to an edge detected version of the second image and finally faded to the final image.
			catch { exec /usr/bin/ppmfade -base temp/crater_transition -f temp/9-map.ppm -l temp/8-crater.ppm -edge } result
		} elseif { $crater_distort_mode == 4} {
			# -bentley  The first image is faded to a "Bentley Effect" version of the first image.
			# This is then faded to a "Bentley Effect" version of the second image and finally faded to the final image.
			catch { exec /usr/bin/ppmfade -base temp/crater_transition -f temp/9-map.ppm -l temp/8-crater.ppm -bentley } result
		} else {
			# crater_distort_mode 0 and 6
			# ppmrelief - run a Laplacian relief filter on a portable pixmap
			catch { exec /usr/bin/ppmfade -base temp/crater_transition -f temp/9-map.ppm -l temp/8-crater.ppm -relief } result
		}
		puts $result
		puts "choose crater_transition.00$crater_fade_number.ppm"
		catch { exec cp temp/crater_transition.00$crater_fade_number.ppm temp/9-map.ppm } result
		puts $result
	} else {
		# no craters used
		catch { exec /usr/bin/ppmforge -clouds -power $pow_map -width 600 -height 300 -mesh 1024 -dimension $dim_map > temp/9-map.ppm } result
	}
	puts $result
	
	puts ""
	puts "########## 3. smoothing..."
	catch { exec pnmsmooth -size 5 5 temp/9-map.ppm > temp/10-map_smooth.ppm } result
	if {$result != ""} { puts $result }
	
	#puts "creating temp/colormap$randmap.ppm from color_maps/colormap$randmap.jpg"
	catch { exec convert color_maps/colormap$randmap.jpg -compress none temp/colormap$randmap.ppm } result
	if {$result != ""} { puts $result }
	catch {exec pnmremap -map=temp/colormap$randmap.ppm temp/10-map_smooth.ppm > temp/11-map_color_remap.ppm } result
	if { $invert_map < 0.5 } {
		puts "invert map"
		catch { exec pnminvert temp/11-map_color_remap.ppm > temp/12-intermediate_map.ppm } result
	} else {
		catch { exec cp temp/11-map_color_remap.ppm temp/12-intermediate_map.ppm } result
	}
	#catch { exec pnmcut temp/12-intermediate_map.ppm -left 30 -right 286 -top 30 -bottom 286 > temp/13-template_day.ppm } result
	catch { exec cp temp/12-intermediate_map.ppm temp/13-template_day.ppm } result
	#catch { exec pnmcut temp/11-map_color_remap.ppm -left 287 -right 542 -top 30 -bottom 286 > temp/14-map_dark.ppm } result
	catch { exec cp temp/11-map_color_remap.ppm temp/14-map_dark.ppm } result
	catch { exec ppmbrighten -v -70 temp/14-map_dark.ppm > temp/15-template_night.ppm } result
	if {$result != ""} { puts $result }
	
	puts "########## 4. generating planet_day map ..."
	# using map=temp/13-template_day.ppm and night_map=temp/15-template_night.ppm
	puts "xplanet -body mars -date \"24 Jun 2020 13:02:17\" -radius 40 -num_times 1 -origin phobos -localtime 9 -north body -config configs/xplanet_day.conf -output temp/16-planet_day.ppm"
	catch {exec xplanet -body mars -date "24 Jun 2020 13:02:17" -radius 40 -num_times 1 -origin phobos -localtime 9 -north body -config configs/xplanet_day.conf -output temp/16-planet_day.ppm } result
	if {$result == ""} {
		puts "ok"
	} else {
		puts $result
	}
	puts "########## 5. generating atmos_ready map ..."
	# using map=temp/4-atmos_template.ppm and night_map=temp/6-atmos_night_template.ppm
	catch {exec xplanet -body mars -date "24 Jun 2020 13:02:17" -radius 40 -num_times 1 -origin phobos -localtime 9 -north body -config configs/xplanet_night.conf -output temp/17-atmos_ready.ppm } result
	if {$result == ""} {
		puts "ok"
	} else {
		puts $result
	}
	
	puts "########## 6. blend together planet_day with atmos_ready ..."	
	catch { exec ppmmix $mixer temp/16-planet_day.ppm temp/17-atmos_ready.ppm > temp/18-complete.ppm } result 
	
	puts "########## 7. scaling to $output_size ..."	
	catch { exec pnmscale $output_size temp/18-complete.ppm > temp/planet_s1.ppm } result
	#catch { exec pnmscale 0.17 temp/18-complete.ppm > temp/planet_s2.ppm } result
	#catch { exec pnmscale 0.14 temp/18-complete.ppm > temp/planet_s3.ppm } result
	#catch { exec pnmscale 0.11 temp/18-complete.ppm > temp/planet_s4.ppm } result
	#catch { exec pnmscale 0.09 temp/18-complete.ppm > temp/planet_s5.ppm } result
	#catch { exec pnmscale 0.07 temp/18-complete.ppm > temp/planet_s6.ppm } result
	#catch { exec pnmscale 0.06 temp/18-complete.ppm > temp/planet_s7.ppm } result

	catch { exec ppmtojpeg temp/planet_s1.ppm > planets/planet_s1_$numb.jpg } result
	#catch { exec ppmtojpeg temp/planet_s2.ppm > planets/planet_s2_$numb.jpg } result
	#catch { exec ppmtojpeg temp/planet_s3.ppm  > planets/planet_s3_$numb.jpg } result
	#catch { exec ppmtojpeg temp/planet_s4.ppm  > planets/planet_s4_$numb.jpg } result
	#catch { exec ppmtojpeg temp/planet_s5.ppm  > planets/planet_s5_$numb.jpg } result
	#catch { exec ppmtojpeg temp/planet_s6.ppm  > planets/planet_s6_$numb.jpg } result
	#catch { exec ppmtojpeg temp/planet_s7.ppm  > planets/planet_s7_$numb.jpg } result
	puts ""	
	
	# save progress
	set fileid [open configs/planet_progress_count w]
 		puts $fileid $numb
 	close $fileid
	#exec sleep 8
	#catch {exec display planets/planet_s1_$numb.jpg } result
	# ###### clean up 
	#exec rm -Rf temp/* ppmfade.*
}
