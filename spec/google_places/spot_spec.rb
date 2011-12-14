require 'spec_helper'

describe GooglePlaces::Spot do

  before :each do
    @lat = '-33.8670522'
    @lng = '151.1957362'
    @radius = 200
    @sensor = false
    @reference = "CoQBeAAAAO-prCRp9Atcj_rvavsLyv-DnxbGkw8QyRZb6Srm6QHOcww6lqFhIs2c7Ie6fMg3PZ4PhicfJL7ZWlaHaLDTqmRisoTQQUn61WTcSXAAiCOzcm0JDBnafqrskSpFtNUgzGAOx29WGnWSP44jmjtioIsJN9ik8yjK7UxP4buAmMPVEhBXPiCfHXk1CQ6XRuQhpztsGhQU4U6-tWjTHcLSVzjbNxoiuihbaA"
  end

  context 'List spots' do
    use_vcr_cassette 'list_spots'

    after(:each) do
      @collection.map(&:class).uniq.should == [GooglePlaces::Spot]
    end

    it 'should be a collection of Spots' do
      @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor)
    end

    describe 'with a single type' do
      use_vcr_cassette 'list_spots_with_single_type'

      before(:each) do
        @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor, :types => 'cafe')
      end

      it 'should have Spots with a specific type' do
        @collection.each do |spot|
          spot.types.should include('cafe')
        end
      end
    end

    describe 'with multiple types' do
      use_vcr_cassette 'list_spots_with_multiple_types'

      before(:each) do
        @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor, :types => ['food','establishment'])
      end

      it 'should have Spots with specific types' do
        @collection.each do |spot|
          (spot.types & ['food', 'establishment']).should be_any
        end
      end
    end

    describe 'searching by name' do
      use_vcr_cassette 'list_spots_with_name'

      before(:each) do
        @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor, :name => 'italian')
      end

      # Apparently the Google Places API returns spots with
      # other names than "italian" as well. Disabled this
      # test for now.
      it 'should have Spots with a specific name' do
        pending 'Disabled due to unpredictable API results'

        #@collection.each do |spot|
        #  spot.name.downcase.should include('italian')
        #end
      end
    end

    describe 'searching by name and types' do
      use_vcr_cassette 'list_spots_with_name_and_types'

      before(:each) do
        @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor, :types => ['food','establishment'], :name => 'italian')
      end

      # Apparently the Google Places API returns spots with
      # other names than "italian" as well. Disabled this
      # test for now.
      it 'should have Spots with a specific name' do
        pending 'Disabled due to unpredictable API results'

        #@collection.each do |spot|
        #  spot.name.downcase.should include('italian')
        #end
      end

      it 'should have Spots with specific types' do
        @collection.each do |spot|
          (spot.types & ['food', 'establishment']).should be_any
        end
      end
    end

    describe 'searching by types with exclusion' do
      use_vcr_cassette 'list_spots_with_types_and_exclusion'

      it 'should exclude spots with type "restaurant"' do
        @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor, :types => ['food','establishment'], :exclude => 'restaurant')

        @collection.map(&:types).each do |types|
          types.should_not include('restaurant')
        end
      end

      it 'should exclude spots with type "restaurant" and "cafe"' do
        @collection = GooglePlaces::Spot.list(@lat, @lng, api_key, :radius => @radius, :sensor => @sensor, :types => ['food','establishment'], :exclude => ['restaurant', 'cafe'])

        @collection.map(&:types).each do |types|
          types.should_not include('restaurant')
          types.should_not include('cafe')
        end
      end
    end

  end

  context 'Find a single spot' do
    use_vcr_cassette 'single_spot'

    before :each do
      @spot = GooglePlaces::Spot.find(@reference, api_key, :sensor => @sensor)
    end

    it 'should be a Spot' do
      @spot.class.should == GooglePlaces::Spot
    end

    %w(reference vicinity lat lng name icon types id formatted_phone_number formatted_address address_components rating url types).each do |attribute|
      it "should have the attribute: #{attribute}" do
        @spot.respond_to?(attribute).should == true
      end
    end
  end

end
