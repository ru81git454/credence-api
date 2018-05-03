# frozen_string_literal: true

require_relative './spec_helper'

describe 'Test Project Handling' do
  include Rack::Test::Methods

  before do
    wipe_database
  end

  it 'HAPPY: should be able to get list of all projects' do
    Credence::Project.create(DATA[:projects][0]).save
    Credence::Project.create(DATA[:projects][1]).save

    get 'api/v1/projects'
    _(last_response.status).must_equal 200

    result = JSON.parse last_response.body
    _(result.count).must_equal 2
  end

  it 'HAPPY: should be able to get details of a single project' do
    proj_data = DATA[:projects][1]
    Credence::Project.create(proj_data).save
    id = Credence::Project.first.id

    get "/api/v1/projects/#{id}"
    _(last_response.status).must_equal 200

    result = JSON.parse last_response.body
    _(result['id']).must_equal id
    _(result['name']).must_equal proj_data['name']
  end

  it 'SAD: should return error if unknown project requested' do
    get '/api/v1/projects/foobar'

    _(last_response.status).must_equal 404
  end

  describe 'Creating New Projects' do
    before do
      @req_header = { 'CONTENT_TYPE' => 'application/json' }
      @proj_data = DATA[:projects][1]
    end

    it 'HAPPY: should be able to create new projects' do
      post 'api/v1/projects', @proj_data.to_json, @req_header
      _(last_response.status).must_equal 201
      _(last_response.header['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']
      proj = Credence::Project.first

      _(created['id']).must_equal proj.id
      _(created['name']).must_equal @proj_data['name']
      _(created['repo_url']).must_equal @proj_data['repo_url']
    end

    it 'BAD: should not create project with illegal attributes' do
      bad_data = @proj_data.clone
      bad_data['created_at'] = '1900-01-01'
      post 'api/v1/projects', bad_data.to_json, @req_header

      _(last_response.status).must_equal 400
      _(last_response.header['Location']).must_be_nil
    end
  end
end
