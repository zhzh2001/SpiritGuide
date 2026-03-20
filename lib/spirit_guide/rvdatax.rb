module SpiritGuide
  # Utilities for dealing with `.rvdatax` files.
  module RVDataX
    require_relative "ksy/rvdatax"

    module Localization
      def display_name
        SpiritGuide.lang == 'zh' ? name : name_en
      end

      def display_desc
        SpiritGuide.lang == 'zh' ? desc : desc_en
      end
    end

    # A dragon definition.
    class Dragon
      include Localization
      attr_accessor :id, :name, :name_en, :desc, :desc_en, :area, :area_en, :type, :base_talents, :base_params, :rarity,
                    :ev_gain, :base_skills, :learn_skills, :learn_talents, :traits, :capture_pool, :capture_chance, :offset

      def display_area
        SpiritGuide.lang == 'zh' ? area : area_en
      end

      def scope
        Kernel.binding
      end
    end

    # Parse all dragon definitions from a binary reading stream representing a `Creatures.rvdatax` file.
    def parse_dragons(stream)
      rvdatax = Rvdatax.from_file(stream)
      index = 1
      rvdatax.entries.map do |entry|
        result = Dragon.new
        result.id = index
        result.name = entry.name

        scope = result.scope
        Kernel.eval(entry.contents, scope)

        index += 1
        result
      end
    end

    module_function :parse_dragons

    # A dragon active skill definition.
    class Skill
      include Localization
      attr_accessor :id, :name, :name_en, :desc, :desc_en, :icon, :type, :category, :channel, :power, :sp_cost, :traits

      def scope
        Kernel.binding
      end
    end

    # Parse all skill definitions from a binary reading stream representing a `Skills.rvdatax` file.
    def parse_skills(stream)
      rvdatax = Rvdatax.from_file(stream)
      index = 1
      rvdatax.entries.map do |entry|
        if entry.contents.strip.empty?
          index += 1
          next
        end

        result = Skill.new
        result.id = index
        result.name = entry.name

        scope = result.scope
        Kernel.eval(entry.contents, scope)

        if result.display_name.nil? || result.display_name.strip.empty?
          index += 1
          next
        end

        index += 1
        result
      end.compact
    end

    module_function :parse_skills

    # A dragon equipped item definition.
    class Accessory
      include Localization
      attr_accessor :id, :name, :name_en, :desc, :desc_en, :icon, :category, :rarity, :price, :sell_price,
                    :trigger_script, :effect_script, :traits, :attr_mod, :attr_gain, :party_effect

      def scope
        Kernel.binding
      end
    end

    # Parse all accessory definitions from a binary reading stream representing a `HoldItems.rvdatax` file.
    def parse_accessories(stream)
      rvdatax = Rvdatax.from_file(stream)
      index = 1
      rvdatax.entries.map do |entry|
        if entry.contents.strip.empty?
          index += 1
          next
        end

        result = Accessory.new
        result.id = index
        result.name = entry.name

        scope = result.scope
        Kernel.eval(entry.contents, scope)

        if result.display_name.nil? || result.display_name.strip.empty?
          index += 1
          next
        end

        index += 1
        result
      end.compact
    end

    module_function :parse_accessories

    # A dragon status effect definition.
    class StatusEffect
      include Localization
      attr_accessor :id, :name, :desc, :icon, :category, :desc_en, :name_en

      def scope
        Kernel.binding
      end
    end

    # Parse all statis effect definitions from a binary reading stream representing a `States.rvdatax` file.
    def parse_status_effects(stream)
      rvdatax = Rvdatax.from_file(stream)
      index = 1
      rvdatax.entries.map do |entry|
        if entry.contents.strip.empty?
          index += 1
          next
        end

        result = StatusEffect.new
        result.id = index
        result.name = entry.name

        scope = result.scope
        Kernel.eval(entry.contents, scope)

        if result.display_name.nil? || result.display_name.strip.empty?
          index += 1
          next
        end

        index += 1
        result
      end.compact
    end

    module_function :parse_status_effects

    # A dragon passive trait definition.
    class Talent
      include Localization
      attr_accessor :id, :name, :desc, :icon, :category, :desc_en, :name_en

      def scope
        Kernel.binding
      end
    end

    # Parse all passive trait definitions from a binary reading stream representing a `Talents.rvdatax` file.
    def parse_talents(stream)
      rvdatax = Rvdatax.from_file(stream)
      index = 1
      rvdatax.entries.map do |entry|
        if entry.contents.strip.empty?
          index += 1
          next
        end

        result = Talent.new
        result.id = index
        result.name = entry.name

        scope = result.scope
        Kernel.eval(entry.contents, scope)

        if result.display_name.nil? || result.display_name.strip.empty?
          index += 1
          next
        end

        index += 1
        result
      end.compact
    end

    module_function :parse_talents
  end
end
