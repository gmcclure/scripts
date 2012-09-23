#!/usr/bin/env ruby

require 'mechanize'
require 'pp'

EEE_URL = 'https://eee.uci.edu/myeee/'
WS_URL  = 'http://writing.colostate.edu/'

def first_and_last_names(namestring)
  # name format must be LAST, FIRST
  names = /([a-zA-Z-]+), ([a-zA-Z-]+)/.match(namestring)
  [names[2], names[1]]
end

# EEE
eee_agent = Mechanize.new

puts "Saying hello to EEE."
eee_page = eee_agent.get(EEE_URL)

puts "Going to sign-in page."
eee_page.form_with(:action => '/myeee/') do |f|
  eee_page = eee_agent.submit(f, f.buttons.first)
end

puts "Logging in."
eee_page.form_with(:name => 'webauth_login_form') do |f|
  f.ucinetid = 'gmcclure'
  f.password = 'QGqMqPi2'
  eee_page = eee_agent.submit(f, f.buttons.first)
end

eee_page = eee_agent.get(EEE_URL)

puts "Going to class dashboard."
eee_page = eee_agent.page.link_with(:href => 'dashboard/F12/25508').click

puts "Going to student list."
eee_page = eee_agent.page.link_with(:id => 'classmates-tab').click

students = Array.new

eee_page.search('tr.row').each do |row|
  s = []
  s.push(row.search('td.person').text)
  s.push(row.search('td.email').text)
  students.push(s)
end

# Test Data
# students = [["McClure, Greg", "gmcclure@thirdstone.net"], ["Johnson, Ronson", "samplestudent2@suremail.info"]]
pp students

# Writing Studio
ws_agent = Mechanize.new

puts
puts "Logging into the Writing Studio."
ws_page = ws_agent.get(WS_URL)
ws_page.form_with(:name => 'loginform1') do |f|
  f.Login = 'gmcclure@uci.edu'
  f.Password = 'uGri6A44'
  ws_page = ws_agent.submit(f, f.buttons.first)
end

puts "Going to page for class 25508."
ws_page = ws_agent.page.link_with(:text => %r{25508}).click

puts "Going through the roster."
ws_page = ws_agent.page.link_with(:text => %r{Class Roster}).click
ws_page = ws_agent.page.link_with(:text => %r{Invite a New Student}).click

# Roster loop
students.each do |student|
  student_names = first_and_last_names(student[0])
  student_name = student_names.join(' ')

  ws_page.form_with(:name => 'search2') do |f|
    puts "Searching for #{student[1]}."
    f.searchstring = student[1]
    ws_page = ws_agent.submit(f, f.buttons.first)
  end

  if ws_page.search('//p[contains(text(),"We were unable to locate")]').length > 0
    puts "Unable to locate #{student_name}."
    ws_page.form_with(:name => 'CFForm_2') do |f|
      ws_page = ws_agent.submit(f, f.buttons.first)
    end

    ws_page.form_with(:name => 'CFForm_2') do |f|
      f.FirstName = student_names[0]
      f.LastName = student_names[1]
      # For some reason, the email field isn't capitalized like the other form fields ...
      f.email = student[1]
      f.StudentPassword = 'abc123'
      f.Confirm = 'abc123'
      ws_page = ws_agent.submit(f, f.buttons.first)
    end
  else
    ws_page = ws_agent.page.link_with(:href => %r{roster_invite}).click
    puts "#{student_name} found and invited."
  end
end
