#required
require "yaml"
require "tty-prompt"
require "tty-color"
require "pastel"

#tty inits
prompt = TTY::Prompt.new(symbols: {marker: "♦"}, active_color: :cyan)
pastel = Pastel.new

#ascii "The Sims" title
def ascii_title
  File.readlines("../docs/ascii_title.txt") do |line|
    puts line
  end
end

#saving created sims to the database file
def save_created_sim(name, gender, life_stage, trait)
    sim_id = {:id => {:name => name, :gender => gender, :life_stage => life_stage, :trait => trait}}
    File.open("../data/database.yml", "a+") { |doc| doc.write(sim_id.to_yaml) }
    puts "Hooray, you've successfully created #{name}!"
end

#(NOT YET CORRECTLY IMPLEMENTED) ensuring no name double ups for sims by checking the sim library 
def does_name_exist(name)
    log = File.read("../data/database.yml")
    name_validation = false
    YAML::load_stream(log) do |doc| 
        next if name != doc[:id][:name]
            name_validation = true 
            return name_validation
        end
end

#selecting from saved sims
def read_sim_library
    log = File.read("../data/database.yml")
    saved_sims_options = []
    YAML::load_stream(log) do |doc| 
        saved_sims_options << "#{doc[:id][:name]}"
    end
return saved_sims_options
end

#(NOT YET WORKING) deleting sims
# def delete_sim(sim)
#     log = File.open("../data/database.yml")
#     YAML::load_stream(log) do |doc| 
#         next unless sim == doc[:id][:name]
#             delete.(doc)
#             puts "You've successfully deleted #{sim}"
#         else
#             puts "Error"
#             break
#         end
#     end
#end

#finding the sim's trait for probability calculations
def find_trait(sim)
    log = File.read("../data/database.yml")
    YAML::load_stream(log) do |doc| 
            if sim == doc[:id][:name]
            $selected_sim_trait = doc[:id][:trait]
            else
                next 
            end
        return $selected_sim_trait
    end
end

#randomise interaction response
def probability_generator(array)
    rand_num = rand(5)
    rand_index_generation = array[rand_num]
    outcome = $outcome_options[rand_index_generation]
    return outcome
end

#IN PROGRESS
def save_interactions(interaction_outcome, initiating_sim, receiving_sim)
    occured_interactions = []
    occured_interactions << interaction_outcome #wrong. this is going to put "Success!" or "Uh oh..." in the array
end

#arrays for the menu options
home_menu_options = ["Create a Sim!", "Choose a Sim to play", "Delete Sims", "Read the instructions", "Exit"]
gender_options = ["female", "male"]
life_stage_options = ["baby", "child", "adult", "elder"]
trait_options = ["friendly", "mean"]
interaction_options = ["Become friends", "Become enemies"]
$outcome_options = ["Success!", "Uh oh..."]

#probabilities
friendly_probability = [[0, 0, 0, 0, 0], [0, 0, 0, 1, 1]] #friendly sim choosing to become friends will be 100% successful, friendly sim trying to become enemies will be 60% successful
mean_probability = [[0, 0, 0, 1, 1], [0, 0, 0, 0, 0]] #mean sim choosing to become friends will be 60% successful, mean sim trying to become enemies will be 100% successful

#menu
puts pastel.cyan("Created by Emily Mills © 2020")
puts ascii_title
puts "Welcome to The Sims: Command Line Edition!"
sleep(0.5)
user_selection = 0
until user_selection == home_menu_options[-1]
user_selection = prompt.select("What would you like to do?", home_menu_options)
case user_selection
when home_menu_options[0] #create a sim
    sleep(0.5)
    input_gender = prompt.select("Choose your Sim's gender:", gender_options)
    if input_gender == "female"
        sleep(0.5)
        input_life_stage = prompt.select("What's her life stage?", life_stage_options)
    elsif input_gender == "male"
        sleep(0.5)
        input_life_stage = prompt.select("What's his life stage?", life_stage_options)
    end
    if input_gender == "female"
        sleep(0.5)
        input_trait = prompt.select("What kind of Sim will she be?", trait_options)
    elsif input_gender == "male"
        sleep(0.5)
        input_trait = prompt.select("What kind of Sim will he be?", trait_options)
    end
    sleep(0.5)
    puts "Finally, give your Sim a first name:"
    input_name = gets.strip.capitalize
    name_created = does_name_exist(input_name)
    if name_created == true 
        puts pastel.bright_yellow("You have already saved a Sim with that name! Please try again with a different name, or delete the original Sim.")
    else name_created == false
        save_created_sim(input_name, input_gender, input_life_stage, input_trait)
    end
    #need to loop back and allow user to enter a different name
    
    sleep(1)
when home_menu_options[1] #choose a sim to play
    sim_library = YAML.load(File.read("../data/database.yml"))
    if sim_library == false || read_sim_library.size < 2
        puts pastel.bright_yellow("Oops! You need to create at least two Sims first. Please make a different selection.")
        next
    else
    selected_sim = prompt.select("Please select a Sim", read_sim_library)
    end
    updated_sim_selections = read_sim_library
    updated_sim_selections.each_with_index do |sim, index|
        if sim == selected_sim
            updated_sim_selections.delete_at(index)
            updated_sim_selections.insert(index, {:name => "#{selected_sim}", :disabled => "(already selected)" })
        else 
            next
        end
    end
    recipient_sim = prompt.select("And who would you like #{selected_sim} to interact with?", updated_sim_selections) 
    chosen_interaction = prompt.select("How would you like #{selected_sim} to interact with #{recipient_sim}?", interaction_options)
    find_trait(selected_sim) 
        if chosen_interaction == interaction_options[0] && $selected_sim_trait == "friendly" #friendly selects become friends
            result = probability_generator(friendly_probability[0])
            puts result
            save_interactions(result, selected_sim, recipient_sim)
        elsif chosen_interaction == interaction_options[1] && $selected_sim_trait == "friendly" #friendly selects become enemies
            result = probability_generator(friendly_probability[1])
            puts result
            save_interactions(result, selected_sim, recipient_sim)
            sleep(0.5)
                if result == $outcome_options[1]
                puts "Because #{selected_sim} is friendly, they didn't have what it takes to be mean this time. #{selected_sim} and #{recipient_sim} are now friends :)"
                end
        elsif chosen_interaction == interaction_options[0] && $selected_sim_trait == "mean" #mean selects become friends
            result = probability_generator(mean_probability[0])
            puts result
            save_interactions(result, selected_sim, recipient_sim)
            sleep(0.5)
                if result == $outcome_options[1]
                puts "Because #{selected_sim} is mean, they failed to make friends this time! #{selected_sim} and #{recipient_sim} are now enemies :("
                end
        elsif chosen_interaction == interaction_options[1] && $selected_sim_trait == "mean" #mean selects become enemies 
            result = probability_generator(mean_probability[1])
            puts result
            # if result == $outcome_options[0]
            #     save_interactions(enemies, selected_sim, recipient_sim)
            # elsif result == $outcome_options[1]
            #     save_interactions(friends, selected_sim, recipient_sim)
            # else
            #     puts "Error"
            # end
        else
            puts "Oh dear, we've run into a problem with the app. Please contact the creator."
        end
    sleep(1)
when home_menu_options[2] #delete sims
    sim_library_status = read_sim_library
    if sim_library_status == []
    puts pastel.bright_yellow("Create some Sims first, and then you can come back here if you'd like to delete them.")
    else
    sim_to_delete = prompt.select("Which Sim would you like to delete? (Be careful! This action cannot be undone.)", read_sim_library) 
    #delete_sim(sim_to_delete)
    end
    sleep(1)
when home_menu_options[3] #read the instructions
    #code
    sleep(1)
end
end


#when this game is ready to be shared, you need to replace your database.yml file with a template (because you don't want other people to have your database!). Maybe a git-ignore on the yml file?
#add option for erasing saved file and starting again? Maybe this could be a command line argument that wipes the yaml file

