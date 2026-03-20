require_relative "spirit_guide/version"
require_relative "spirit_guide/rgss3"
require_relative "spirit_guide/graphics"
require_relative "spirit_guide/rvdatax"
require_relative "spirit_guide/scripts"
require_relative "spirit_guide/icons"

require "erb"
require "fileutils"
require "csv"

# General Dragon Spirits utilities.
module SpiritGuide
  class << self
    attr_accessor :lang
  end
  @lang = 'en'

  # The six stats.
  STATS = %i[hp atk mat def mdf spd].freeze

  # The types a dragon/skill can be.
  DRAGON_TYPES = %i[fire wind water thunder earth dark light void].freeze

  # The categories a skill can be.
  SKILL_CATEGORIES = %i[other physical magical support].freeze

  # The categories a status effect can be.
  EFFECT_CATEGORIES = %i[negative positive negative_team positive_team 4 5 other].freeze

  # Get the skill learning table.
  def learnings_table(scripts)
    skill_csv = scripts.find { |script| script.name == "Skill_CSV" }
    eval(skill_csv.contents)
    CSV.parse(SKILL_LEARNINGS)
  end

  module_function :learnings_table

  # Get the skill pool a dragon can learn.
  def skill_pool(dragon, table)
    found = table.find { |row| row[0].to_i == dragon.id }
    eval(found[2]).values
  end

  module_function :skill_pool
end

if __FILE__ == $PROGRAM_NAME
  SpiritGuide.lang = ARGV[1] == 'zh' ? 'zh' : 'en'

  # gather data
  dragons = []
  File.open("#{ARGV[0]}/GameData/Creatures.rvdatax", "rb") do |file|
    dragons = SpiritGuide::RVDataX.parse_dragons(file)
  end

  skills = []
  File.open("#{ARGV[0]}/GameData/Skills.rvdatax", "rb") do |file|
    skills = SpiritGuide::RVDataX.parse_skills(file)
  end

  items = SpiritGuide::RGSS3.rvdata2_to_json(Marshal.load(File.read("#{ARGV[0]}/Data/Items.rvdata2",
                                                                    binmode: true))).compact
  items.each do |item|
    item.instance_eval(item.note)
  end

  accessories = []
  File.open("#{ARGV[0]}/GameData/HoldItems.rvdatax", "rb") do |file|
    accessories = SpiritGuide::RVDataX.parse_accessories(file)
  end

  effects = []
  File.open("#{ARGV[0]}/GameData/States.rvdatax", "rb") do |file|
    effects = SpiritGuide::RVDataX.parse_status_effects(file)
  end

  talents = []
  File.open("#{ARGV[0]}/GameData/Talents.rvdatax", "rb") do |file|
    talents = SpiritGuide::RVDataX.parse_talents(file)
  end

  icons = SpiritGuide::Icons.get_icons(ARGV[0])

  scripts = SpiritGuide::Scripts.rvdata2_to_scripts(Marshal.load(File.read("#{ARGV[0]}/Data/Scripts.rvdata2",
                                                                           binmode: true)))
  learnings = SpiritGuide.learnings_table(scripts)
  skill_pools = dragons.to_h do |dragon, _|
    [dragon.id, SpiritGuide.skill_pool(dragon, learnings)]
  end

  # utils for rendering
  def render(page, *args)
    ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/#{page}.rhtml")).result(Kernel.binding)
  end

  def flatten_talents(tids)
    result = [tids[0]]
    if tids[1].instance_of?(Integer)
      result << tids[1]
    else
      result << tids[1][0] unless tids[1][0].zero?
      result << tids[1][1] unless tids[1][1].zero?
    end
    result
  end

  def effect_category(cat)
    case cat
    when 0
      "Negative (Single-Target)"
    when 1
      "Positive (Single-Target)"
    when 2
      "Negative (Field)"
    when 3
      "Positive (Field)"
    when 6
      "Other"
    else
      cat.to_s
    end
  end

  def js_string_escape(str)
    str.to_s.gsub(/\\/, "\\\\").gsub(/"/, "\\\"")
  end

  # define scopes for page executions
  def main_scope(title, contents)
    Kernel.binding
  end

  def dragon_scope(dragon, dragons, skills, accessories, effects, talents, items, skill_pool)
    Kernel.binding
  end

  def skill_scope(skill, dragons, skill_pools)
    Kernel.binding
  end

  def acc_scope(accessory)
    Kernel.binding
  end

  def se_scope(effect)
    Kernel.binding
  end

  def talent_scope(talent, dragons)
    Kernel.binding
  end

  # util functions
  def copy_image(src, dest)
    File.write(dest, SpiritGuide::Graphics.rvdata2_to_png(
                       File.read(
                         src,
                         binmode: true
                       )
                     ), binmode: true)
  end

  def render_page(title, contents)
    main_template = ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/page.rhtml"))
    main_template.result(main_scope(title, contents))
  end

  def more_or_less(sym)
    case sym
    when :<=
      "or less"
    when :>=
      "or more"
    else
      "(error: #{sym})"
    end
  end

  def greater_or_lesser(sym)
    case sym
    when :<=
      "less than (or equal to)"
    when :>=
      "greater than (or equal to)"
    else
      "(error: #{sym})"
    end
  end

  # export HTML of data
  dragon_template = ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/dragon.rhtml"))
  FileUtils.mkdir_p("pages/dragon")
  FileUtils.mkdir_p("pages/assets/dragon")
  FileUtils.mkdir_p("pages/assets/card")
  dragons.each do |dragon|
    copy_image("#{ARGV[0]}/Graphics/Battlers/d_#{dragon.id}.rvdata2", "pages/assets/dragon/#{dragon.id}.png")
    copy_image("#{ARGV[0]}/Graphics/System/DragonCards/c_#{dragon.id}.rvdata2", "pages/assets/card/#{dragon.id}.png")
    File.write("pages/dragon/#{dragon.id}.html",
               render_page(dragon.display_name,
                           dragon_template.result(dragon_scope(dragon, dragons, skills, accessories, effects, talents, items,
                                                               skill_pools[dragon.id]))))
  end

  skill_template = ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/skill.rhtml"))
  FileUtils.mkdir_p("pages/skill")
  FileUtils.mkdir_p("pages/assets/skill")
  skills.each do |skill|
    SpiritGuide::Icons.get_icon(icons, skill.icon).write("pages/assets/skill/#{skill.icon}.png")
    File.write("pages/skill/#{skill.id}.html",
               render_page(skill.display_name, skill_template.result(skill_scope(skill, dragons, skill_pools))))
  end

  acc_template = ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/accessory.rhtml"))
  FileUtils.mkdir_p("pages/accessory")
  FileUtils.mkdir_p("pages/assets/accessory")
  accessories.each do |acc|
    SpiritGuide::Icons.get_icon(icons, acc.icon).write("pages/assets/accessory/#{acc.id}.png")
    File.write("pages/accessory/#{acc.id}.html",
               render_page(acc.display_name, acc_template.result(acc_scope(acc))))
  end

  se_template = ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/effect.rhtml"))
  FileUtils.mkdir_p("pages/effect")
  FileUtils.mkdir_p("pages/assets/effect")
  effects.each do |se|
    SpiritGuide::Icons.get_icon(icons, se.icon).write("pages/assets/effect/#{se.id}.png")
    File.write("pages/effect/#{se.id}.html",
               render_page(se.display_name, se_template.result(se_scope(se))))
  end

  talent_template = ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/talent.rhtml"))
  FileUtils.mkdir_p("pages/talent")
  talents.each do |talent|
    File.write("pages/talent/#{talent.id}.html",
               render_page(talent.display_name, talent_template.result(talent_scope(talent, dragons))))
  end

  # export HTML of static pages
  File.write("pages/index.html",
             render_page("", ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/index.rhtml")).result))
  File.write("pages/about.html",
             render_page("About", ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/about.rhtml")).result))
  File.write("pages/search.html",
             render_page("Search", ERB.new(File.read("#{File.dirname(__FILE__)}/../templates/search.rhtml")).result))

  # export other assets
  first_dragon_type_icon_id = 18 * 16 + 0
  FileUtils.mkdir_p("pages/assets/type")
  SpiritGuide::DRAGON_TYPES.each_with_index do |sym, i|
    SpiritGuide::Icons.get_icon(icons, first_dragon_type_icon_id + i).write("pages/assets/type/#{sym}.png")
  end
  copy_image("pages/assets/type/void.png", "pages/assets/type/none.png")

  first_category_icon_id = 22 * 16 + 10
  FileUtils.mkdir_p("pages/assets/skillcat")
  SpiritGuide::Icons.get_icon(icons, 0).write("pages/assets/skillcat/other.png")
  SpiritGuide::SKILL_CATEGORIES[1..].each_with_index do |sym, i|
    SpiritGuide::Icons.get_icon(icons, first_category_icon_id + i).write("pages/assets/skillcat/#{sym}.png")
  end
end
